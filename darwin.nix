{ lib, pkgs, nix-vscode-extensions, ... }: {
  system.primaryUser = "oliver";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.oliver.home = "/Users/oliver";

  # Set fish as the default shell
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

      # # Workaround for the following issue:
      # # - https://github.com/LnL7/nix-darwin/issues/122
      # # - https://d12frosted.io/posts/2021-05-21-path-in-fish-with-nix-darwin.html
      # for p in (string split " " $NIX_PROFILES); fish_add_path --prepend --move --path $p/bin; end

      # # https://github.com/wfxr/forgit/blob/17394d10569899eded337dec59ef461f8becea51/README.md#homebrew
      # [ -f $HOMEBREW_PREFIX/share/forgit/forgit.plugin.fish ]; and source $HOMEBREW_PREFIX/share/forgit/forgit.plugin.fish
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
      # Play feedback when volume is changed.
      # TODO: not working?
      "com.apple.sound.beep.feedback" = 1;
      AppleKeyboardUIMode = 2;
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  # Note: this should only be used when installing via Nix is not possible.
  homebrew = {
    enable = true;
    taps = [ "TomAnthony/brews" ];
    brews = [
      # Not available via nix-darwin.
      # "asimov"
      # Outdated in nixpkgs.
      # "forgit"
      # Install via Brew rather than Nix so we can utilize system services
      # (start on login).
      "caddy"
    ];
    masApps = {
      # Keynote = 409183694;
      # Numbers = 409203825;
      # OctaVerify = 490179405;
      # rcmd = 1596283165;
      # UniFI = 1057750338;
      # Xcode = 497799835;
    };
    # Most of these GUIs are not available in Nix. Furthermore, when I did try
    # to install some of these using Nix, I experienced various issues e.g.
    # configuration was reset each time Nix was re-applied. It is for these
    # reasons that I use Homebrew casks instead.
    casks = [
      "1password"
      # "adobe-creative-cloud"
      # "airflow"
      # "docker"
      "figma"
      # "firefox"
      "ghostty"
      "google-chrome"
      # "google-chrome@canary"
      "istherenet"
      # "iterm2"
      "linear-linear"
      # "messenger"
      # "obsidian"
      "raycast"
      # "screen-studio"
      "slack"
      "spotify"
      # "stats"
      "transmission"
      # "tunnelbear"
      "visual-studio-code"
      # "vlc"
      "zed"
      "zoom"
    ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
}
