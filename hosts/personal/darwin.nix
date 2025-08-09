{ lib, pkgs, ... }: {
  imports = [ ../common/darwin.nix ];

  homebrew = {
    casks = [
      "transmission"
    ];
  };
}
