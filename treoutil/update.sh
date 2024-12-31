#!/usr/bin/env bash

cd /etc/nixos
nix flake update

nixos-rebuild switch
