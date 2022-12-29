#!/usr/bin/env bash

cd ~

for d in rust*
do
    cd $d
    echo $d
    git status --short --branch --untracked-files=no --ignore-submodules --no-ahead-behind --no-renames
    cd ..
done
