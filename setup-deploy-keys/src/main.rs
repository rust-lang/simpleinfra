use std::env;
use std::fs;
use std::process::{Command, Stdio};

fn main() {
    let remotes = run_capture(Command::new("git").arg("remote").arg("show"));
    let remotes = remotes
        .trim()
        .split('\n')
        .filter(|l| !l.is_empty())
        .collect::<Vec<_>>();

    let url = remotes.iter()
        .map(|remote| {
            run_capture(Command::new("git")
                .arg("config")
                .arg(format!("remote.{}.url", remote)))
        })
        .find(|url| url.contains("git@github.com:"))
        .expect("found no suitable remote");
    println!("remote: {}", url);
    let url = url.trim();
    let pos = url.find(':').unwrap();
    let slug = &url[pos + 1..];
    let date = run_capture(Command::new("date").arg("+%Y-%m-%d"));
    let date = date.trim();
    let comment = format!("{} {}", slug, date);

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
        .arg(format!("https://api.github.com/repos/{}/keys", slug))
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
