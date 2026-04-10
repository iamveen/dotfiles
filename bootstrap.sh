#!/usr/bin/env bash

sudo apt -y update
sudo apt -y install curl

curl -LsSf https://astral.sh/uv/install.sh | sh
