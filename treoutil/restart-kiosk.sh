#!/usr/bin/env bash

pkill firefox

tmux new-session -d firefox --kiosk https://stregsystem.fklub.dk
