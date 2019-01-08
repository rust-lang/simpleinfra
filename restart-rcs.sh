#!/bin/bash

# Initial deployment instructions:
#
#    mkdir -p /opt/rcs/logs/nginx /opts/rcs/data/letsencrypt
#    # copy secrets.toml.example to /opt/rcs/data and configure it
#
# And... I think that's it!

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

TARGET_BOX=rcs.rust-lang.org

ssh $TARGET_BOX $(aws ecr get-login --no-include-email --region us-west-1)
ssh $TARGET_BOX '
    set -o errexit &&
    set -o pipefail &&
    set -o nounset &&
    set -o xtrace &&
    cd /opt/rcs &&
    (test -d data || (echo "no data dir" && exit 1)) &&
    docker pull 890664054962.dkr.ecr.us-west-1.amazonaws.com/rust-central-station:latest &&
    (docker rm -f rcs || true) &&
    docker run \
        --name rcs \
        --volume `pwd`/data:/data \
        --volume `pwd`/data/letsencrypt:/etc/letsencrypt \
        --volume /dev/log:/dev/log \
        --publish 80:80 \
        --publish 443:443 \
        --rm \
        --detach \
        890664054962.dkr.ecr.us-west-1.amazonaws.com/rust-central-station:latest
'
