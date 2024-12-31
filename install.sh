#!/usr/bin/env sh

set -e

# Ensure correct working directory.
cd "$(dirname "$0")"

nix run nix-darwin -- switch --flake .

chsh -s /run/current-system/sw/bin/fish

./configure-mac.sh

ln -s "$PWD"/config/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
ln -s "$PWD"/config/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -s "$PWD"/config/vscode/snippets/ ~/Library/Application\ Support/Code/User/snippets

caddy start -c "$PWD"/proxy/Caddyfile

# https://github.com/stevegrunwell/asimov#installation-via-homebrew
sudo brew services start asimov
