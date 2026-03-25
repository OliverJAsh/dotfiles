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

    width=
    prev=
    has_display=0

    for arg in "$@"; do
      case "$arg" in
        --display|--display=*)
          has_display=1
          ;;
        --width=*)
          width="''${arg#--width=}"
          ;;
        *)
          if [ "$prev" = '--width' ]; then
            width="$arg"
          fi
          ;;
      esac

      prev="$arg"
    done

    if [ "$has_display" -eq 1 ]; then
      exec difft "$@"
    fi

    if [ -z "$width" ]; then
      width="$(tput cols 2>/dev/null || printf '80')"
    fi

    if [ "$width" -lt 140 ]; then
      display=inline
    else
      display=side-by-side
    fi

    exec difft --display "$display" "$@"
  '';
}
