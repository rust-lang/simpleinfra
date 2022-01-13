#!/bin/bash

set -euxo pipefail

if [ ! -e x.py ]; then
    echo "Should be run from a rust-lang/rust checkout"
    exit 1
fi

SIMPLEINFRA_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

git fetch git@github.com:rust-lang/rust
CURRENT_STABLE=`git ls-remote -q git@github.com:rust-lang/rust stable | awk '{ print $1 }'`
git checkout $CURRENT_STABLE

git submodule update --init -- src/tools/cargo

cd src/tools/cargo

./publish.py
CARGO_VERSION=$(cargo read-manifest | jq -r .version)
$SIMPLEINFRA_DIR/with-rust-key.sh git tag -m "$CARGO_VERSION release" -u FA1BE5FE $CARGO_VERSION
