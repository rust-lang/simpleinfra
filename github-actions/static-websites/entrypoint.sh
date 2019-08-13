#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

deploy_dir="${GITHUB_WORKSPACE}/${INPUT_DEPLOY_DIR}"
github_token="${INPUT_GITHUB_TOKEN}"
cloudfront_distribution="${INPUT_CLOUDFRONT_DISTRIBUTION-}"

export AWS_ACCESS_KEY_ID="${INPUT_AWS_ACCESS_KEY_ID-}"
export AWS_SECRET_ACCESS_KEY="${INPUT_AWS_SECRET_ACCESS_KEY-}"

# Ensure GitHub doesn't mess around with the uploaded file.
# Without the file, for example, files with an underscore in the name won't be
# included in the pages.
touch "${deploy_dir}/.nojekyll"

# Push the website to GitHub pages
cd "${deploy_dir}"
rm -rf .git
git init
git config user.name "Deploy from CI"
git config user.email ""
git add .
git commit -m "Deploy ${GITHUB_SHA} to gh-pages"
git push -f "https://x-token:${github_token}@github.com/${GITHUB_REPOSITORY}" master:gh-pages

# Invalidate the CloudFront caches to prevent stale content from being served.
if [[ -n "${cloudfront_distribution}" ]]; then
    aws cloudfront create-invalidation --distribution-id "${cloudfront_distribution}" --paths "/*"
fi
