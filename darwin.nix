{ lib, pkgs, nix-vscode-extensions, ... }: {
  system.primaryUser = "oliver";

  system.stateVersion = 6;

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.oliver.home = "/Users/oliver";

  users.users.oliver.shell = pkgs.fish;
  # https://github.com/nix-darwin/nix-darwin/issues/1237
  users.knownUsers = [ "oliver" ];
  users.users.oliver.uid = 501;

  nix.settings.experimental-features = "nix-command flakes";

  programs.fish = {
    enable = true;

    shellInit = ''
      # As per Homebrew installation instructions.
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
  };

  environment.shells = [ pkgs.fish ];

  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      wvous-br-corner = 1; # Disabled - default is "Quick Note"
      persistent-apps = [];
    };

    NSGlobalDomain = {
      "com.apple.keyboard.fnState" = true;
      # https://github.com/nix-darwin/nix-darwin/issues/1207
      "com.apple.mouse.tapBehavior" = 1;
      # Play feedback when volume is changed.
      "com.apple.sound.beep.feedback" = 1;
      AppleKeyboardUIMode = 2;
    };

    # https://github.com/nix-darwin/nix-darwin/issues/1207
    trackpad.TrackpadThreeFingerDrag = true;

    universalaccess.closeViewScrollWheelToggle = true;

    controlcenter.Sound = true;
  };

  security.pam.services.sudo_local.touchIdAuth = true;

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
      rcmd = 1596283165;
    };
    # Most of these GUIs are not available in Nix. Furthermore, when I did try
    # to install some of these using Nix, I experienced various issues e.g.
    # configuration was reset each time Nix was re-applied. It is for these
    # reasons that I use Homebrew casks instead.
    casks = [
      "1password"
      "figma"
      # TODO: Ghostty
      # Fix alt+e in Fish:
      # macos-option-as-alt = true
      # Configuring it via home-manager results in thin cursor for some reason, and
      # the setting doesn't work.
      "ghostty"
      "google-chrome"
      "google-chrome@beta"
      "istherenet"
      "linear-linear"
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
