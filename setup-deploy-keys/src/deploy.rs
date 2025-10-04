use std::env;
use std::fs;
use std::io::Write;
use std::os::unix::net::UnixStream;
use std::os::unix::prelude::*;
use std::process::{Command, Stdio};

fn main() {
    let slug = env::var("BUILD_REPOSITORY_ID")
        .or_else(|_| env::var("GITHUB_REPOSITORY"))
        .unwrap_or_else(|_| "unknown".to_string());

    let msg = env::var("BUILD_SOURCEVERSIONMESSAGE")
        .or_else(|_| env::var("GITHUB_COMMIT_MESSAGE"))
        .unwrap_or_else(|_| "Deploy from CI".to_string());

    let mut sock_path = env::temp_dir();
    sock_path.push("deploy.sock");
    
    let stream = match UnixStream::connect(&sock_path) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("Failed to connect to socket: {}", e);
            std::process::exit(1);
        }
    };

    let mut stream = stream;
    let payload = format!("deploy {}", slug);
    if let Err(e) = stream.write_all(payload.as_bytes()) {
        eprintln!("Failed to send deploy request: {}", e);
        std::process::exit(1);
    }

    let _ = fs::remove_dir_all(".git");
    run(Command::new("git").arg("init"));

    // --- FIXED CONFIG ---
    run(Command::new("git")
        .arg("config")
        .arg("user.name")
        .arg("CI Bot"));
    run(Command::new("git")
        .arg("config")
        .arg("user.email")
        .arg("ci@example.com"));

    run(Command::new("git").arg("add").arg("."));

    let status_output = run(Command::new("git").arg("status").arg("--porcelain"));
    if status_output.trim().is_empty() {
        println!("No changes to commit, skipping commit.");
    } else {
        run(Command::new("git").arg("commit").arg("-m").arg(&msg));
    }
}

// Helper 
fn run(cmd: &mut Command) -> String {
    let output = cmd
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .output()
        .expect("failed to execute command");

    if !output.status.success() {
        eprintln!(
            "Command failed: {:?}\nstdout: {}\nstderr: {}",
            cmd,
            String::from_utf8_lossy(&output.stdout),
            String::from_utf8_lossy(&output.stderr)
        );
        std::process::exit(1);
    }

    String::from_utf8_lossy(&output.stdout).to_string()
}
