#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

TARGET_BOX=rcs.rust-lang.org
RCS_BOX_USER=$USER

rsync -avr --delete rcs-data/ $RCS_BOX_USER@$TARGET_BOX:/opt/rcs/data/
ssh $RCS_BOX_USER@$TARGET_BOX '
    set -o errexit &&
    set -o pipefail &&
    set -o nounset &&
    cd /opt/rcs &&
    test -d data &&
    docker pull alexcrichton/rust-central-station &&
    (docker rm -f rcs || true) &&
    docker run \
        --name rcs \
        --volume `pwd`/data:/data \
        --volume `pwd`/data/letsencrypt:/etc/letsencrypt \
        --volume `pwd`/logs:/var/log \
        --publish 80:80 \
        --publish 443:443 \
        --rm \
        --detach \
        alexcrichton/rust-central-station
'
