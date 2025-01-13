#!/usr/bin/env bash

cd /etc/nixos

sudo -u treo git pull

nix flake update

nixos-rebuild switch
