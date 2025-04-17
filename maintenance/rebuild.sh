#!/usr/bin/env bash

set -e
if ! [ -f /etc/nixos/flake.nix ]; then
    git clone https://github.com/f-klubben/Strandvejen /etc/nixos
    cd /etc/nixos
else
    cd /etc/nixos
    git pull
fi
nix flake update
nixos-rebuild switch

if [[ $(jq -r ".restart" $MAINTENANCE_FILE) == "true" ]]; then
    reboot
fi
