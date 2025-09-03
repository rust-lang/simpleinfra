use std::env;
use std::io::Write;
use std::os::unix::net::UnixStream;
use std::os::unix::prelude::*;
use std::process::{Command, Stdio};

fn main() {
    let slug = env::var("BUILD_REPOSITORY_ID")
        .or_else(|_| env::var("GITHUB_REPOSITORY"))
        .unwrap();
    let key = env::var("GITHUB_DEPLOY_KEY").unwrap();

    let socket = "/tmp/.github-deploy-socket";
    run(Command::new("ssh-agent").arg("-a").arg(socket));
    while UnixStream::connect(socket).is_err() {
        std::thread::sleep(std::time::Duration::from_millis(5));
    }

    // decode base64 → pipe ke ssh-add via stdin
    let mut decode = Command::new("base64")
        .arg("-d")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .unwrap();

    decode
        .stdin
        .take()
        .unwrap()
        .write_all(key.as_bytes())
        .unwrap();

    let mut ssh_add = Command::new("ssh-add")
        .arg("-") // baca key dari stdin
        .env("SSH_AUTH_SOCK", socket)
        .stdin(Stdio::piped())
        .spawn()
        .unwrap();

    // pipe decode.stdout ke ssh-add.stdin
    {
        let mut ssh_stdin = ssh_add.stdin.take().unwrap();
        let mut decode_stdout = decode.stdout.take().unwrap();
        std::io::copy(&mut decode_stdout, &mut ssh_stdin).unwrap();
    }

    decode.wait().unwrap();
    ssh_add.wait().unwrap();

    let sha = env::var("BUILD_SOURCEVERSION")
        .or_else(|_| env::var("GITHUB_SHA"))
        .unwrap();
    let msg = format!("Deploy {sha} to gh-pages");

    let _ = std::fs::remove_dir_all(".git");
    run(Command::new("git").arg("init"));
    run(Command::new("git")
        .arg("config")
        .arg("user.name")
        .arg("Deploy from CI"));
    run(Command::new("git").arg("config").arg("user.email").arg(""));
    run(Command::new("git").arg("add").arg("."));
    run(Command::new("git").arg("commit").arg("-m").arg(&msg));
    run(Command::new("git")
        .arg("push")
        .arg(format!("git@github.com:{slug}"))
        .arg("master:gh-pages")
        .env("GIT_SSH_COMMAND", "ssh -o StrictHostKeyChecking=no")
        .env("SSH_AUTH_SOCK", socket)
        .arg("-f"));
}

fn run(cmd: &mut Command) {
    println!("{cmd:?}");
    let status = cmd.status().unwrap();
    assert!(status.success());
}
