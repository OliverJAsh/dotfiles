{ lib, pkgs, ... }: {
  imports = [ ../common/darwin.nix ];

  homebrew = {
    masApps = {
      "1Password for Safari" = 1569813296;
    };
    casks = [
      "plex-media-server"
      "transmission"
    ];
  };
}
