#!/usr/bin/env bash

set -ex

sudo locale-gen en_US
sudo locale-gen en_US.UTF-8
sudo localedef -i en_US -f UTF-8 en_US.UTF-8
sudo update-locale LANG="en_US.UTF-8" LANGUAGE="en_US" LC_ALL="en_US.UTF-8"

export LANGUAGE=en_US
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

sudo -E -H pip install --upgrade pip
