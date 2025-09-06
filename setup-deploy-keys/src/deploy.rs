use std::env;
use std::fs;
use std::os::unix::net::UnixStream;
use std::os::unix::prelude::*;
use std::process::{Command, Stdio};
use std::io::Write;

fn main() {
    let slug = env::var("BUILD_REPOSITORY_ID")
        .or_else(|_| env::var("GITHUB_REPOSITORY"))
        .unwrap();
    let key_b64 = env::var("GITHUB_DEPLOY_KEY").unwrap();

    let socket = "/tmp/.github-deploy-socket";
    run(Command::new("ssh-agent").arg("-a").arg(socket));
    while UnixStream::connect(socket).is_err() {
        std::thread::sleep(std::time::Duration::from_millis(5));
    }

    // Pipe base64-decoded deploy key directly into ssh-add
    let mut ssh_add = Command::new("ssh-add")
        .arg("-")
        .env("SSH_AUTH_SOCK", socket)
        .stdin(Stdio::piped())
        .spawn()
        .expect("failed to spawn ssh-add");

    {
        let mut child = Command::new("base64")
            .arg("-d")
            .stdin(Stdio::piped())
            .stdout(ssh_add.stdin.take().unwrap())
            .spawn()
            .expect("failed to spawn base64");

        child
            .stdin
            .as_mut()
            .unwrap()
            .write_all(key_b64.as_bytes())
            .expect("failed to write key to base64 stdin");

        let status = child.wait().expect("failed to wait on base64");
        if !status.success() {
            panic!("base64 decoding failed");
        }
    }

    let status = ssh_add.wait().expect("failed to wait on ssh-add");
    if !status.success() {
        panic!("ssh-add failed with exit code {:?}", status.code());
    }

    let sha = env::var("BUILD_SOURCEVERSION")
        .or_else(|_| env::var("GITHUB_SHA"))
        .unwrap();
    let msg = format!("Deploy {sha} to gh-pages");

    let _ = fs::remove_dir_all(".git");
    run(Command::new("git").arg("init"));
    run(Command::new("git").arg("config").arg("user.name").arg("Deploy from CI"));
    run(Command::new("git").arg("config").arg("user.email").arg(""));
    run(Command::new("git").arg("add").arg("."));
    run(Command::new("git").arg("commit").arg("-m").arg(&msg));
}

fn run(cmd: &mut Command) {
    let status = cmd.status().unwrap();
    if !status.success() {
        panic!("command {:?} failed with {:?}", cmd, status.code());
    }
}
