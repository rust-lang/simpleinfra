#!/bin/bash

curl https://dev-static.rust-lang.org/dist/channel-rust-1.35.0.toml > channel-rust-stable.toml
aws s3 cp ./channel-rust-stable.toml s3://dev-static-rust-lang-org/dist/
# E30AO2GXMDY230 is dev-static.rust-lang.org distribution ID
aws cloudfront create-invalidation \
    --distribution-id E30AO2GXMDY230 \
    --paths /dist/channel-rust-stable.toml
rm channel-rust-stable.toml
echo "dev-static is published hourly, or you can manually trigger a run if you have RCS access"
