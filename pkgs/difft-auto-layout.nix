{ pkgs }:

# https://github.com/Wilfred/difftastic/issues/693
pkgs.writeShellApplication {
  name = "difft-auto-layout";
  runtimeInputs = [
    pkgs.difftastic
    pkgs.ncurses
  ];
  text = ''
    set -euo pipefail

    columns="''${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"

    if test "$columns" -lt 140; then
        difft --display inline "$@"
    else
        difft --display side-by-side "$@"
    fi
  '';
}
