{ lib, pkgs, ... }: {
  imports = [ ../common/darwin.nix ];

  homebrew = {
    casks = [
      "plex-media-server"
      "transmission"
    ];
  };
}
