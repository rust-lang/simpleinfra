# upload-docker-image

The `upload-docker-image` action uploads a Docker image to the Rust
Infrastructure team's ECR registry. There is no stability guarantee for this
action, since it's supposed to only be used in infra managed by us.

## Usage

To use the action add this to your workflow:

```yaml
- uses: rust-lang/simpleinfra/github-actions/upload-docker-image@master
  with:
    image: local-image-name
    repository: ecr-repository-name
    region: us-west-1
    aws_access_key_id: "${{ secrets.aws_access_key_id }}"
    aws_secret_access_key: "${{ secrets.aws_secret_access_key }}"
```

## Development

The action is written in NodeJS 12, and you can install the dependencies with:

```
npm install
```

GitHub Actions requires all the dependencies to be committed, so before
creating a commit you need to run:

```
npm run build
```

The command will bundle everything in `dist/index.js`. That file will need to
be committed.
