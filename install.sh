#!/usr/bin/env sh
set -e

sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install build-essential unzip stow tree entr pkg-config libssl-dev fish stow
sudo chsh -s $(which fish) $USER

curl https://mise.run | sh
$(cd $HOME/dotfiles/stow && stow --target "$HOME" *)
$HOME/.local/bin/mise install
