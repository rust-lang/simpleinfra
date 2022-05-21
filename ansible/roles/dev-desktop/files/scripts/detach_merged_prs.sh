#!/usr/bin/env bash

for d in rust*
do
    cd $d
    echo $d
    # if the fast forward is successful, this branch is merged, so we can kill it
    git pull upstream master --ff-only && git checkout --detach && git submodule update --init --recursive
    cd ..
done
