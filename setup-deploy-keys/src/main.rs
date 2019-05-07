use std::env;
use std::fs;
use std::process::{Command, Stdio};
use structopt::StructOpt;
use chrono::Utc;

#[derive(StructOpt)]
struct Cli {
    #[structopt(help = "the name of the repository to setup")]
    repo: String,
}

fn main() {
    let cli = Cli::from_args();
    let date = Utc::today().format("%Y-%m-%d");
    let comment = format!("{} {}", cli.repo, date);

    let gh_token = env::var("GITHUB_TOKEN").expect("no GITHUB_TOKEN env var");

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

    let data = format!("{{\
        \"title\":\"CI deploy key {}\",\
        \"key\":\"{}\",\
        \"read_only\":false\
    }}", date, pubkey.trim());

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

    run(Command::new("curl")
        .arg("-i")
        .arg("-H").arg("Accept: application/vnd.github.v3+json")
        .arg("-H").arg(format!("Authorization: token {}", gh_token))
        .arg(format!("https://api.github.com/repos/{}/keys", cli.repo))
        .arg("-d").arg(&data));

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
