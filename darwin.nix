{ lib, pkgs, ... }:
{
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.oliver.home = "/Users/oliver";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  nix.settings.experimental-features = "nix-command flakes";

  programs.fish = {
    enable = true;

    shellInit = ''
      # As per Homebrew installation instructions.
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # Workaround for the following issue:
      # - https://github.com/LnL7/nix-darwin/issues/122
      # - https://d12frosted.io/posts/2021-05-21-path-in-fish-with-nix-darwin.html
      for p in (string split " " $NIX_PROFILES); fish_add_path --prepend --move --path $p/bin; end
    '';
  };

  environment.shells = [ pkgs.fish ];

  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      wvous-br-corner = 1; # Disabled - default is "Quick Note"
    };

    NSGlobalDomain = {
      AppleShowScrollBars = "Always";
      # Play feedback when volume is changed.
      "com.apple.sound.beep.feedback" = 1;
    };
  };

  security.pam.enableSudoTouchIdAuth = true;

  # Note: this should only be used when installing via Nix is not possible.
  homebrew = {
    enable = true;
    taps = [
      "TomAnthony/brews"
    ];
    brews = [
      # Not available via nix-darwin.
      # https://github.com/LnL7/nix-darwin/issues/129
      # TODO: replace with localias?
      # https://github.com/peterldowns/localias
      "nginx"
      # Not available via Nix.
      "itermocil"
    ];
    masApps = {
      Numbers = 409203825;
      rcmd = 1596283165;
      Xcode = 497799835;
    };
    # Most of these GUIs are not available in Nix. Furthermore, when I did try
    # to install some of these using Nix, I experienced various issues e.g.
    # configuration was reset each time Nix was re-applied. It is for these
    # reasons that I use Homebrew casks instead.
    casks = [
      "1password"
      "airflow"
      "cron"
      "docker"
      "firefox"
      "google-chrome"
      "iterm2"
      "linear-linear"
      "obsidian"
      "raycast"
      "screen-studio"
      "slack"
      "spotify"
      "transmission"
      "vlc"
      "whatsapp"
      "zoom"
    ];
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "github-copilot-cli"
    "vscode"
  ];
}
