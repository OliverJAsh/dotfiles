#!/usr/bin/env sh

set -e

cd ~/Code
mkcd -p ./unsplash/
gh repo clone unsplash/unsplash-web
cd ./unsplash-web/
ln -s /Users/oliver/Library/Mobile\ Documents/com~apple~CloudDocs/dotfiles/unsplash-web-env ./.env
echo "use flake" > ./.envrc
direnv allow
yarn
