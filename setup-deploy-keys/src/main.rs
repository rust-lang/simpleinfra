use chrono::Utc;
use reqwest::{
    header::{HeaderValue, ACCEPT, AUTHORIZATION, USER_AGENT},
    Client,
};
use std::error::Error;
use std::fs;
use std::process::Command;
use structopt::StructOpt;

#[derive(StructOpt)]
struct Cli {
    #[structopt(help = "the name of the repository to setup")]
    repo: String,
    #[structopt(long = "github-token", env = "GITHUB_TOKEN", help = "GitHub API key")]
    github_token: String,
    #[structopt(long = "rsa")]
    rsa: bool,
}

fn main() -> Result<(), Box<dyn Error>> {
    let cli = Cli::from_args();
    let date = Utc::today().format("%Y-%m-%d");
    let comment = format!("{} {}", cli.repo, date);

    println!("generating the ssh key...");
    // https://security.stackexchange.com/questions/143442/what-are-ssh-keygen-best-practices
    run(Command::new("ssh-keygen")
        .arg("-t")
        .arg(if cli.rsa { "rsa" } else { "ed25519" })
        .arg("-a")
        .arg("100")
        .arg("-f")
        .arg("_ssh_keygen_tmp_out")
        .arg("-q")
        .arg("-N")
        .arg("") // no passphrase
        .arg("-C")
        .arg(&comment));
    let key = fs::read_to_string("_ssh_keygen_tmp_out").unwrap();
    let key = base64::encode(&key);
    fs::remove_file("_ssh_keygen_tmp_out").unwrap();
    let pubkey = fs::read_to_string("_ssh_keygen_tmp_out.pub").unwrap();
    fs::remove_file("_ssh_keygen_tmp_out.pub").unwrap();

    println!("GITHUB_DEPLOY_KEY={}", key);

    println!("uploading the deploy key...");
    let client = Client::new();
    client
        .post(&format!("https://api.github.com/repos/{}/keys", cli.repo))
        .header(
            USER_AGENT,
            HeaderValue::from_static("rust-lang/simpleinfra"),
        )
        .header(
            ACCEPT,
            HeaderValue::from_static("application/vnd.github.v3+json"),
        )
        .header(
            AUTHORIZATION,
            HeaderValue::from_str(&format!("token {}", cli.github_token))?,
        )
        .json(&serde_json::json!({
            "title": format!("CI deploy key - {} - {}", cli.repo, date),
            "key": pubkey.trim(),
            "read_only": false,
        }))
        .send()?
        .error_for_status()?;

    println!();
    println!("the deploy key has been configured!");
    println!("please use the shared configuration snippets in the simpleinfra repo to use it");
    Ok(())
}

fn run(cmd: &mut Command) {
    let status = cmd.status().unwrap();
    assert!(status.success());
}
