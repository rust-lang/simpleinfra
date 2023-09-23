# Upload Metrics Artifact

This GitHub Action will upload metrics collected by CI run to GitHub Artifacts.
This allows for future runners or other actions to download the artifact and
upload them to S3 bucket that is used for monitoring GitHub CI.

You can follow the discussion in [the relevant GitHub issue][issue-source].

## Usage

If the default metrics' file path is `build/cpu-usage.csv`, you don't need to
pass any argument to the runner.

Note: the default metrics' file path for Rust compiler repository is
`build/cpu-usage.csv` as you can see in the workflow file
[here][rust-cpu-collector-ci] and [here][rust-cpu-collector-script].

```yaml
- name: Upload metrics artifact
  uses: rust-lang/simpleinfra/github-actions/upload-metrics-artifact@master
```

If the metrics is stored in a different file, you can pass the path to the
action:

```yaml
- name: Upload metrics artifact
  uses: rust-lang/simpleinfra/github-actions/upload-metrics-artifact@master
  with:
    metrics-filepath: |
      file1.csv
      file2.csv
      file3.csv
```

## Development

This is a composite GitHub Action, and as such, you can run the action using
[`act`][act-github]. You can also use one of the above syntaxes in your own
fork of this repository.

[issue-source]: https://github.com/rust-lang/infra-team/issues/74
[act-github]: https://github.com/nektos/act
[rust-cpu-collector-ci]: https://github.com/rust-lang/rust/blob/1.72.1/.github/workflows/ci.yml#L90
[rust-cpu-collector-script]: https://github.com/rust-lang/rust/blob/1.72.1/src/ci/scripts/collect-cpu-stats.sh#L10
