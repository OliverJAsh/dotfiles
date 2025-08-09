{ lib, pkgs, ... }: {
  system.primaryUser = "oliver";
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.oliver.home = "/Users/oliver";

  nix.settings.experimental-features = "nix-command flakes";

  # Common system defaults shared between all machines
  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      wvous-br-corner = 1; # Disabled - default is "Quick Note"
      persistent-apps = [];
    };

    NSGlobalDomain = {
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
    masApps = {
      rcmd = 1596283165;
    };
    casks = [
      "1password"
      "istherenet"
      "raycast"
      "spotify"
    ];
  };

  nixpkgs.config.allowUnfree = true;
}
