use clap::Parser;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime};

/// Clean up unused build/target directories in user home directories
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

fn is_project_dir(dir: &Path) -> bool {
    (dir.join("x.py").is_file() && dir.join("build").is_dir())
        || (dir.join("Cargo.toml").is_file() && dir.join("target").is_dir())
}

fn find_cache_dirs(home: &Path) -> io::Result<Vec<PathBuf>> {
    let mut result = Vec::new();
    for entry in fs::read_dir(home)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_dir() {
            // Recursively search for project dirs
            let mut stack = vec![path];
            while let Some(dir) = stack.pop() {
                if is_project_dir(&dir) {
                    if dir.join("build").is_dir() {
                        result.push(dir.join("build"));
                    }
                    if dir.join("target").is_dir() {
                        result.push(dir.join("target"));
                    }
                } else if let Ok(entries) = fs::read_dir(&dir) {
                    for e in entries.flatten() {
                        if e.path().is_dir() {
                            stack.push(e.path());
                        }
                    }
                }
            }
        }
    }
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
        let dir = tempdir().unwrap();
        File::create(dir.path().join("x.py")).unwrap();
        fs::create_dir(dir.path().join("build")).unwrap();
        assert!(is_project_dir(dir.path()));
    }

    #[test]
    fn test_is_project_dir_cargo_target() {
        let dir = tempdir().unwrap();
        File::create(dir.path().join("Cargo.toml")).unwrap();
        fs::create_dir(dir.path().join("target")).unwrap();
        assert!(is_project_dir(dir.path()));
    }

    #[test]
    fn test_is_project_dir_false() {
        let dir = tempdir().unwrap();
        assert!(!is_project_dir(dir.path()));
    }
}
