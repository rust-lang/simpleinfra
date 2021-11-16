const TEAM_URL: &str = "https://team-api.infra.rust-lang.org/v1/teams/all.json";

use eyre::*;
use serde::Deserialize;
use std::collections::HashSet;
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
    Command::new(cmd).args(args).output()
}

const KEY_DIR: &str = "/etc/ssh/authorized_keys/";

fn main() -> Result<()> {
    let all = reqwest::blocking::get(TEAM_URL)?
        .json::<All>()
        .wrap_err("failed to fetch team repository")?;
    let mut users = HashSet::new();
    for person in all.members {
        users.insert(person.github.clone());
        // Get the keys the user added to their github account.
        // Do this every time the cronjob runs so that they get their new keys if necessary.
        let keys = reqwest::blocking::get(format!("https://github.com/{}.keys", person.github))
            .wrap_err("failed to download user's keys")?
            .text()?;
        std::fs::write(format!("{}{}", KEY_DIR, person.github), keys)
            .wrap_err("Failed to create key file")?;

        // Check if user exists
        let id = cmd("id", &[&person.github]).wrap_err("failed to run `id` command")?;
        if id.status.success() {
            continue;
        }

        // If user does not exist, create it
        ensure!(
            cmd("useradd", &["--create-home", &person.github])?
                .status
                .success(),
            "failed to create user"
        );

        // Get them ssh access
        ensure!(
            cmd("usermod", &["-a", "-G", "allow-ssh", &person.github])?
                .status
                .success(),
            "failed to give user ssh access"
        );
    }
    // Delete all keys for users that weren't on the list
    for entry in std::fs::read_dir(KEY_DIR)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_file() {
            if let Some(extension) = path.extension() {
                if extension == "keys" {
                    if let Some(stem) = path.file_stem() {
                        if let Some(stem) = stem.to_str() {
                            if !users.contains(stem) {
                                std::fs::remove_file(path)?;
                            }
                        }
                    }
                }
            }
        }
    }
    Ok(())
}
