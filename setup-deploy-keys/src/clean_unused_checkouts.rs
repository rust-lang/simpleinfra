use clap::Parser;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime};
use walkdir::WalkDir;

/// Clean up unused projects
///
/// This CLI finds all projects that users have checked out on the dev-desktops and deletes
/// temporary files if the project has not been modified in a certain number of days.
///
/// Specifically, the CLI will look for checkouts of `rust-lang/rust` and delete the `build`
/// directory. And it will find unused crates and delete the `target` directory.
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Cli {
    /// Only print directories and their size, do not delete
    #[arg(long)]
    dry_run: bool,

    /// The root directory to search for projects
    #[arg(short, long = "root-directory", default_value = "/home")]
    root_directory: PathBuf,

    /// The maximum age of a project in days
    ///
    /// The CLI will only clean projects that have not been updated in the last `max-age` days.
    #[arg(short, long = "max-age", default_value_t = 60)]
    max_age: u32,
}

fn find_cache_dirs(home: &Path) -> io::Result<Vec<PathBuf>> {
    // Use WalkDir to perform a safe recursive traversal. By default WalkDir does
    // not follow symlinks which prevents accidental symlink loops.
    let mut result = Vec::new();

    for entry in WalkDir::new(home).follow_links(false) {
        let entry = match entry {
            Ok(e) => e,
            Err(_) => continue, // skip entries we can't read
        };

        let path = entry.path();
        if !entry.file_type().is_dir() {
            continue;
        }

        // We're interested in artifact dirs named `build` (python) or
        // `target` (Rust). When we find one, check the parent directory for the
        // expected marker files (`x.py` for python projects, `Cargo.toml` for
        // Rust) before including the artifact directory.
        if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
            match name {
                "build" => {
                    if path
                        .parent()
                        .map(|p| p.join("x.py").is_file())
                        .unwrap_or(false)
                    {
                        result.push(path.to_path_buf());
                    }
                }
                "target" => {
                    if path
                        .parent()
                        .map(|p| p.join("Cargo.toml").is_file())
                        .unwrap_or(false)
                    {
                        result.push(path.to_path_buf());
                    }
                }
                _ => {}
            }
        }
    }

    result.sort();
    result.dedup();
    Ok(result)
}

fn is_unused(dir: &Path, days: u64) -> io::Result<bool> {
    let cutoff = SystemTime::now() - Duration::from_secs(days * 24 * 60 * 60);
    let mut recent = false;
    for entry in walkdir::WalkDir::new(dir.parent().unwrap_or(dir)) {
        let entry = entry?;
        if let Ok(meta) = entry.metadata() {
            if let Ok(modified) = meta.modified() {
                if modified > cutoff {
                    recent = true;
                    break;
                }
            }
        }
    }
    Ok(!recent)
}

fn print_or_delete(dir: &Path, dry_run: bool) {
    if dry_run {
        let size = get_dir_size(dir);
        match size {
            Ok(bytes) => {
                println!(
                    "{:.2} MiB\t{}",
                    bytes as f64 / 1024.0 / 1024.0,
                    dir.display()
                );
            }
            Err(_) => {
                println!("{}", dir.display());
            }
        }
    } else {
        println!("Deleting {}", dir.display());
        let _ = fs::remove_dir_all(dir);
    }
}

fn get_dir_size(path: &Path) -> io::Result<u64> {
    let mut size = 0u64;
    for entry in walkdir::WalkDir::new(path) {
        let entry = entry?;
        if entry.file_type().is_file() {
            size += entry.metadata()?.len();
        }
    }
    Ok(size)
}

fn main() -> io::Result<()> {
    let cli = Cli::parse();
    let cache_dirs = find_cache_dirs(&cli.root_directory)?;
    for dir in cache_dirs {
        if is_unused(&dir, cli.max_age as u64)? {
            print_or_delete(&dir, cli.dry_run);
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs::{self, File};
    use std::io::Write;
    use tempfile::tempdir;

    #[test]
    fn test_get_dir_size_empty() {
        let dir = tempdir().unwrap();
        assert_eq!(get_dir_size(dir.path()).unwrap(), 0);
    }

    #[test]
    fn test_get_dir_size_with_files() {
        let dir = tempdir().unwrap();
        let file_path = dir.path().join("file1");
        let mut file = File::create(&file_path).unwrap();
        file.write_all(&[1u8; 1024]).unwrap();
        assert_eq!(get_dir_size(dir.path()).unwrap(), 1024);
    }

    #[test]
    fn test_is_project_dir_xpy_build() {
        let root = tempdir().unwrap();
        let proj = root.path().join("proj_python");
        fs::create_dir_all(&proj).unwrap();
        File::create(proj.join("x.py")).unwrap();
        fs::create_dir(proj.join("build")).unwrap();

        let found = find_cache_dirs(root.path()).unwrap();
        assert!(found.iter().any(|p| p.ends_with("proj_python/build")));
    }

    #[test]
    fn test_is_project_dir_cargo_target() {
        let root = tempdir().unwrap();
        let proj = root.path().join("proj_rust");
        fs::create_dir_all(&proj).unwrap();
        File::create(proj.join("Cargo.toml")).unwrap();
        fs::create_dir(proj.join("target")).unwrap();

        let found = find_cache_dirs(root.path()).unwrap();
        assert!(found.iter().any(|p| p.ends_with("proj_rust/target")));
    }

    #[test]
    fn test_is_project_dir_false() {
        let root = tempdir().unwrap();
        let proj = root.path().join("proj_none");
        fs::create_dir_all(&proj).unwrap();
        // No marker files or artifact dirs
        let found = find_cache_dirs(root.path()).unwrap();
        assert!(found.is_empty());
    }

    #[test]
    fn test_print_or_delete_flow() {
        let root = tempdir().unwrap();
        let proj = root.path().join("proj_print");
        let build = proj.join("build");
        fs::create_dir_all(&build).unwrap();
        let mut file = File::create(build.join("file.bin")).unwrap();
        file.write_all(&[0u8; 512]).unwrap();

        // dry-run should not remove
        print_or_delete(&build, true);
        assert!(build.exists());

        // actual delete should remove
        print_or_delete(&build, false);
        assert!(!build.exists());
    }

    #[cfg(unix)]
    #[test]
    fn test_find_cache_dirs_symlink_loop() {
        use std::os::unix::fs::symlink;

        let root = tempdir().unwrap();
        let proj = root.path().join("proj_rust_loop");
        fs::create_dir_all(&proj).unwrap();
        File::create(proj.join("Cargo.toml")).unwrap();
        fs::create_dir(proj.join("target")).unwrap();

        // create a symlink that points back to root (possible loop)
        let loop_link = root.path().join("loop");
        let _ = symlink(root.path(), &loop_link);

        let found = find_cache_dirs(root.path()).unwrap();
        assert!(found.iter().any(|p| p.ends_with("proj_rust_loop/target")));
    }
}
