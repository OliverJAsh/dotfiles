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

rm -rf /opt/homebrew/etc/nginx/nginx.conf
ln -s "$PWD"/config/nginx.conf /opt/homebrew/etc/nginx/nginx.conf
brew services start nginx
