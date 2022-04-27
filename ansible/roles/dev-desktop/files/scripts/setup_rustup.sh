#!/usr/bin/env bash

set -x

rustup --version || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

for D in rust*; do
    if [ -d "${D}" ]; then
        rustup toolchain link "$D"_stage1 "$D/build/x86_64-unknown-linux-gnu/stage1"
        rustup toolchain link "$D"_stage2 "$D/build/x86_64-unknown-linux-gnu/stage2"
    fi
done
