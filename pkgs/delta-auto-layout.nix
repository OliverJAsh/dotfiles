{ pkgs }:

# https://github.com/dandavison/delta/issues/359
# https://github.com/dandavison/delta/issues/2083
pkgs.writeShellApplication {
  name = "delta-auto-layout";
  runtimeInputs = [
    pkgs.delta
    pkgs.ncurses
  ];
  text = ''
    set -euo pipefail

    width=
    prev=
    has_side_by_side=0
    has_no_side_by_side=0

    for arg in "$@"; do
      case "$arg" in
        --side-by-side)
          has_side_by_side=1
          ;;
        --no-side-by-side)
          has_no_side_by_side=1
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

    if [ "$has_side_by_side" -eq 1 ] || [ "$has_no_side_by_side" -eq 1 ]; then
      exec delta "$@"
    fi

    if [ -z "$width" ]; then
      width="$(tput cols 2>/dev/null || printf '80')"
    fi

    if [ "$width" -ge 140 ]; then
      exec delta --side-by-side "$@"
    fi

    exec delta "$@"
  '';
}
