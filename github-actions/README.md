# GitHub Actions

This directory contains some shared [GitHub Actions][docs] used on CIs managed
by the Rust Infrastructure team. There are no stability guarantees for these
actions, since they're supposed to only be used in infra managed by us.

[docs]: https://help.github.com/en/articles/about-actions

## static-websites

The `static-websites` action deploys a directory to GitHub pages. To use it add
this to your workflow:

```yaml
- uses: rust-lang/simpleinfra/github-actions/static-websites@master
  with:
    deploy_dir: path/to/output
    github_token: "${{ secrets.github_token }}"
  if: github.ref == 'refs/heads/master'
```

If you also want to invalidate a Cloudfront distribution after a deploy you
need to use:

```yaml
- uses: rust-lang/simpleinfra/github-actions/static-websites@master
  with:
    deploy_dir: path/to/output
    cloudfront_distribution: AAAAAAAAAA
    github_token: "${{ secrets.github_token }}"
    aws_access_key_id: "${{ secrets.aws_access_key_id }}"
    aws_secret_access_key: "${{ secrets.aws_secret_access_key }}"
  if: github.ref == 'refs/heads/master'
```
