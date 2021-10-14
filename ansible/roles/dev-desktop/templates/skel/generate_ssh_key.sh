#!/usr/bin/env bash

ssh-keygen -t ed25519 -C `id -u -n` -N '' -f ~/.ssh/dev_desktop
