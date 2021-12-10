#!/bin/bash

set -euxo pipefail

if [ ! -e x.py ]; then
    echo "Should be run from a rust-lang/rust checkout"
    exit 1
fi

git fetch git@github.com:rust-lang/rust
CURRENT_MASTER=`git ls-remote -q git@github.com:rust-lang/rust master | awk '{ print $1 }'`
BRANCH_POINT=`git log --merges --first-parent --format="%P" -1 $CURRENT_MASTER -- src/version | awk '{print($1)}'`
NEW_BETA_VERSION=`git show $BRANCH_POINT:src/version`
CARGO_SHA=`git rev-parse $BRANCH_POINT:src/tools/cargo`
git push git@github.com:rust-lang/cargo $CARGO_SHA:refs/heads/rust-$NEW_BETA_VERSION

echo "Disable branch protection for beta on rust-lang/rust, then press enter."
read

git push git@github.com:rust-lang/rust $BRANCH_POINT:refs/heads/beta -f

echo "Please reenable branch protection for beta on rust-lang/rust, then press enter."
read
