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

#
# File associations
#

# Find an app ID: https://github.com/moretension/duti/issues/50

# Manually view config file:
# /usr/libexec/PlistBuddy -c "Print" ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
# Delete entry:
# /usr/libexec/PlistBuddy -c "Delete :LSHandlers:1" ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist

duti -s com.microsoft.VSCode .code-snippets all
duti -s com.microsoft.VSCode .css all
duti -s com.microsoft.VSCode .js all
duti -s com.microsoft.VSCode .json all
duti -s com.microsoft.VSCode .jsonc all
duti -s com.microsoft.VSCode .jsx all
duti -s com.microsoft.VSCode .lock all
duti -s com.microsoft.VSCode .log all
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

# This results in an error.
# > failed to set com.microsoft.VSCode as handler for public.html (error -54)
# https://github.com/moretension/duti/issues/29
# https://github.com/moretension/duti/issues/34
# Do it manually for now.
# duti -s com.microsoft.VSCode .html all
