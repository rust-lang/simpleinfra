const TEAM_URL: &str = "https://team-api.infra.rust-lang.org/v1/teams/all.json";

use miniserde::Deserialize;
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

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut handle = curl::easy::Easy::new();
    handle.url(TEAM_URL).unwrap();
    let mut data = Vec::new();
    {
        let mut transfer = handle.transfer();
        transfer
            .write_function(|new_data| {
                data.extend_from_slice(new_data);
                Ok(new_data.len())
            })
            .unwrap();
        transfer.perform().unwrap();
    }

    let data = String::from_utf8(data).unwrap();
    let all: All = miniserde::json::from_str(&data).unwrap();
    let mut users = HashSet::new();
    for person in all.members {
        users.insert(person.github.clone());
        // Get the keys the user added to their github account.
        // Do this every time the cronjob runs so that they get their new keys if necessary.
        let mut keys = Vec::new();
        handle
            .url(&format!("https://github.com/{}.keys", person.github))
            .unwrap();
        {
            let mut transfer = handle.transfer();
            transfer
                .write_function(|new_data| {
                    keys.extend_from_slice(new_data);
                    Ok(new_data.len())
                })
                .unwrap();
            transfer.perform().expect("failed to download user's keys");
        }
        let keys = String::from_utf8(keys).unwrap();
        std::fs::write(format!("{}{}", KEY_DIR, person.github), keys)
            .expect("Failed to create key file");

        // Check if user exists
        let id = cmd("id", &[&person.github]).expect("failed to run `id` command");
        if id.status.success() {
            continue;
        }

        // If user does not exist, create it
        assert!(
            cmd("useradd", &["--create-home", &person.github])?
                .status
                .success(),
            "failed to create user"
        );

        // Get them ssh access
        assert!(
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
