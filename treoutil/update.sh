#!/usr/bin/env bash

cd /etc/nixos

git pull

nix flake update

nixos-rebuild switch
