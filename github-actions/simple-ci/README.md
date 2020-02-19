# simple-ci

The `simple-ci` action allows you to easily build and test your Rust projects.
See [`actions.yml`] for configuration options.

[`actions.yml`]: ./actions.yml

## Examples

### Simple
This builds, tests, and checks the formatting of your project.
```yaml
- uses: rust-lang/simpleinfra/github-actions/simple-ci@master
  with:
    check_fmt: true
```

### Complete Template
This template builds and tests your project on stable, beta, and nightly across
linux, macos, windows.

```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v2
      - run: rustup default ${{ matrix.channel }}
      - uses: rust-lang/simpleinfra/github-actions/simple-ci@master
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        channel: [stable, beta, nightly]
```

## Development

The action is written in NodeJS 12, and you can install the dependencies with:

```
npm install
```

### Running

```
npm start
```

GitHub Actions requires all the dependencies to be committed, so before
creating a commit you need to run:

```
npm run build
```

The command will bundle everything in `dist/index.js`. That file will need to
be committed.
