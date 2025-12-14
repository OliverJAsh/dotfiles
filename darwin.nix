{
  lib,
  pkgs,
  nix-vscode-extensions,
  ...
}:
{
  system.primaryUser = "oliver";
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.oliver = {
    home = "/Users/oliver";
    shell = pkgs.fish;
    uid = 501;
  };
  # https://github.com/nix-darwin/nix-darwin/issues/1237
  users.knownUsers = [ "oliver" ];

  nix.settings.experimental-features = "nix-command flakes";

  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      wvous-br-corner = 1; # Disabled - default is "Quick Note"
      persistent-apps = [ ];
    };

    NSGlobalDomain = {
      # https://github.com/nix-darwin/nix-darwin/issues/1207
      "com.apple.mouse.tapBehavior" = 1;
      # Play feedback when volume is changed.
      "com.apple.sound.beep.feedback" = 1;
      AppleKeyboardUIMode = 2;
      "com.apple.keyboard.fnState" = true;
    };

    # https://github.com/nix-darwin/nix-darwin/issues/1207
    trackpad.TrackpadThreeFingerDrag = true;

    universalaccess.closeViewScrollWheelToggle = true;

    controlcenter.Sound = true;
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  programs.fish = {
    enable = true;

    shellInit = ''
      # As per Homebrew installation instructions.
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
  };

  environment.shells = [ pkgs.fish ];

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    taps = [ "TomAnthony/brews" ];
    brews = [
      # Install via Brew rather than Nix so we can utilize system services
      # (start on login).
      "caddy"
    ];
    masApps = {
      Reeder = 6475002485;
      rcmd = 1596283165;
    };
    casks = [
      "1password"
      "browserstacklocal"
      "figma"
      "firefox"
      "ghostty"
      "gitbutler"
      "google-chrome"
      "google-chrome@beta"
      "istherenet"
      "linear-linear"
      # "plex-media-server"
      "raycast"
      "slack"
      "spotify"
      "stats"
      "transmission"
      "tunnelbear"
      "visual-studio-code"
      "zoom"
    ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
}
