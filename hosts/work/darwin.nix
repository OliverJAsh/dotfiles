{ lib, pkgs, nix-vscode-extensions, ... }: {
  imports = [ ../common/darwin.nix ];

  users.users.oliver.shell = pkgs.fish;
  # https://github.com/nix-darwin/nix-darwin/issues/1237
  users.knownUsers = [ "oliver" ];
  users.users.oliver.uid = 501;

  system.defaults = {
    NSGlobalDomain = {
      "com.apple.keyboard.fnState" = true;
    };
  };

  programs.fish = {
    enable = true;

    shellInit = ''
      # As per Homebrew installation instructions.
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
  };

  environment.shells = [ pkgs.fish ];

  homebrew = {
    taps = [ "TomAnthony/brews" ];
    brews = [
      # Install via Brew rather than Nix so we can utilize system services
      # (start on login).
      "caddy"
    ];
    masApps = {
      rcmd = 1596283165;
    };
    casks = [
      "figma"
      # TODO: Ghostty
      # Fix alt+e in Fish:
      # macos-option-as-alt = true
      # Configuring it via home-manager results in thin cursor for some reason, and
      # the setting doesn't work.
      "ghostty"
      "google-chrome"
      "google-chrome@beta"
      "linear-linear"
      "slack"
      "stats"
      "tunnelbear"
      "visual-studio-code"
      "zoom"
    ];
  };

  nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
}
