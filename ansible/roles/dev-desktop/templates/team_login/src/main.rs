const TEAM_URL: &str = "https://team-api.infra.rust-lang.org/v1/teams/all.json";

use serde::Deserialize;
use eyre::*;
use std::process::Command;
use std::process::Output;

#[derive(Deserialize)]
struct All {
    members: Vec<Person>,
}

#[derive(Deserialize)]
struct Person {
    github: String,
}

fn cmd(cmd: &str, args: &[&str]) -> std::io::Result<Output> {
    Command::new(cmd)
        .args(args)
        .output()
}

fn main() -> Result<()> {
    let all = reqwest::blocking::get(TEAM_URL)?.json::<All>()?;
    for person in all.members {
        // Get the keys the user added to their github account.
        // Do this every time the cronjob runs so that they get their new keys if necessary.
        let keys =
            reqwest::blocking::get(format!("https://github.com/{}.keys", person.github))?.text()?;
        std::fs::write(format!("/etc/ssh/authorized_keys/{}", person.github), keys)?;

        // Check if user exists
        let id = cmd("id", &[&person.github])?;
        if id.status.success() {
            continue;
        }

        // If user does not exist, create it
        ensure!(
            cmd("useradd", &["--create-home", &person.github])?.status.success(),
            "failed to create user"
        );

        // Get them ssh access
        ensure!(
            cmd("usermod", &["-a", "-G", "allow-ssh", &person.github])?.status.success(),
            "failed to give user ssh access"
        );
    }
    bail!("user not found");
}
