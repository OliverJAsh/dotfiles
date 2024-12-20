#!/usr/bin/env sh

set -e

# Remove all apps from dock
# In the future it might be possible to configure this via nix-darwin:
# https://github.com/LnL7/nix-darwin/pull/619
defaults write com.apple.dock persistent-apps -array
# Remove all folders from dock
defaults write com.apple.dock persistent-others -array

# Keyboard navigation to move focus between controls.
# In the future it might be possible to configure this via nix-darwin:
# https://github.com/LnL7/nix-darwin/pull/735
defaults write -g AppleKeyboardUIMode -int 2

killall Dock

# App IDs: https://github.com/moretension/duti/issues/50

duti -s com.microsoft.VSCode .code-snippets all
duti -s com.microsoft.VSCode .css all
# This results in an error. Apparently this is safe to ignore.
# > failed to set com.microsoft.VSCode as handler for public.html (error -54)
# https://github.com/moretension/duti/issues/29
duti -s com.microsoft.VSCode .html all
duti -s com.microsoft.VSCode .js all
duti -s com.microsoft.VSCode .json all
duti -s com.microsoft.VSCode .jsonc all
duti -s com.microsoft.VSCode .jsx all
duti -s com.microsoft.VSCode .lock all
duti -s com.microsoft.VSCode .md all
duti -s com.microsoft.VSCode .nix all
duti -s com.microsoft.VSCode .patch all
duti -s com.microsoft.VSCode .rb all
duti -s com.microsoft.VSCode .sh all
duti -s com.microsoft.VSCode .snap all
duti -s com.microsoft.VSCode .svg all
duti -s com.microsoft.VSCode .tf all
duti -s com.microsoft.VSCode .ts all
duti -s com.microsoft.VSCode .tsx all
duti -s com.microsoft.VSCode .txt all
duti -s com.microsoft.VSCode .vcl all
duti -s com.microsoft.VSCode .xml all
duti -s com.microsoft.VSCode .yml all
duti -s com.microsoft.VSCode com.apple.property-list all
duti -s com.microsoft.VSCode public.data all
