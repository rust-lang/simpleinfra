# simple-ci

The `simple-ci` action allows you to easily build and test your Rust projects.
See [`actions.yml`] for configuration options.

[`actions.yml`]: ./actions.yml

## Example
This example builds an mdbook project on linux.

```yaml
- uses: rust-lang/simpleinfra/github-actions/simple-ci@master
  with:
    check_fmt: true
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
