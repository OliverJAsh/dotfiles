{ lib, pkgs, ... }: {
  home.username = "oliver";
  home.homeDirectory = "/Users/oliver";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}