use std::fs;
use std::process::{Command, Stdio};
use structopt::StructOpt;
use chrono::Utc;
use std::error::Error;
use reqwest::header::{HeaderValue, USER_AGENT, ACCEPT, AUTHORIZATION};

#[derive(StructOpt)]
struct Cli {
    #[structopt(help = "the name of the repository to setup")]
    repo: String,
    #[structopt(long = "github-token", env = "GITHUB_TOKEN", help = "GitHub API key")]
    github_token: String,
}

fn main() -> Result<(), Box<Error>> {
    let cli = Cli::from_args();
    let date = Utc::today().format("%Y-%m-%d");
    let comment = format!("{} {}", cli.repo, date);

    let client = reqwest::Client::new();

    // https://security.stackexchange.com/questions/143442/what-are-ssh-keygen-best-practices
    run(Command::new("ssh-keygen")
        .arg("-t").arg("ed25519")
        .arg("-a").arg("100")
        .arg("-f").arg("_ssh_keygen_tmp_out")
        .arg("-q")
        .arg("-N").arg("") // no passphrase
        .arg("-C").arg(&comment));
    let key = run_capture(Command::new("base64")
        .arg("-w")
        .arg("0")
        .arg("_ssh_keygen_tmp_out"));
    fs::remove_file("_ssh_keygen_tmp_out").unwrap();
    let key = key.trim();
    let pubkey = fs::read_to_string("_ssh_keygen_tmp_out.pub").unwrap();
    fs::remove_file("_ssh_keygen_tmp_out.pub").unwrap();

    if std::path::Path::new(".travis.yml").exists() {
        run(Command::new("travis")
            .arg("env")
            .arg("set")
            .arg("--com")
            .arg("GITHUB_DEPLOY_KEY")
            .arg(key));
    } else {
        println!("GITHUB_DEPLOY_KEY={}", key);
    }

    client.post(&format!("https://api.github.com/repos/{}/keys", cli.repo))
        .header(USER_AGENT, HeaderValue::from_static("rust-lang/simpleinfra"))
        .header(ACCEPT, HeaderValue::from_static("application/vnd.github.v3+json"))
        .header(AUTHORIZATION, HeaderValue::from_str(&format!("token {}", cli.github_token))?)
        .json(&serde_json::json!({
            "title": format!("CI deploy key - {} - {}", cli.repo, date),
            "key": pubkey.trim(),
            "read_only": false,
        }))
        .send()?
        .error_for_status()?;

    println!("

Add this to .travis.yml:

matrix:
  include:
    - name: \"master doc to gh-pages\"
      rust: nightly
      script:
        - cargo doc --no-deps
      deploy:
        provider: script
        script: curl -LsSf https://git.io/fhJ8n | rustc - && (cd target/doc && ../../rust_out)
        skip_cleanup: true
        on:
          branch: master

... or

- job: docs
  steps:
    - template: ci/azure-install-rust.yml
    - script: cargo doc --no-deps --all-features
    - script: curl -LsSf https://git.io/fhJ8n | rustc - && (cd target/doc && ../../rust_out)
      condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/master'))
      env:
        GITHUB_DEPLOY_KEY: $(GITHUB_DEPLOY_KEY)

");

    Ok(())
}

fn run(cmd: &mut Command) {
    println!("{:?}", cmd);
    let status = cmd.status().unwrap();
    assert!(status.success());
}

fn run_capture(cmd: &mut Command) -> String {
    println!("{:?}", cmd);
    let output = cmd.stderr(Stdio::inherit()).output().unwrap();
    assert!(output.status.success());
    String::from_utf8_lossy(&output.stdout).into()
}
