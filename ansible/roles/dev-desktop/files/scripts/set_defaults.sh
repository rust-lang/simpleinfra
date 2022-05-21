#!/usr/bin/env bash

for D in rust*; do
    if [ -d "${D}" ]; then
        pushd $D
            ln -s ../config.toml
        popd
    fi
done
