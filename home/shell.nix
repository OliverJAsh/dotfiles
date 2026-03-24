{ pkgs, ... }:

{
  home.sessionVariables = {
    # Issue: `code` is slow to open files and temporarily opens duplicate
    # VS Code instance in the dock https://github.com/microsoft/vscode/issues/139634
    EDITOR = "code --wait";
    # TODO: -FRX
    # https://stackoverflow.com/questions/32469204/scrolling-down-git-diff-from-mac-terminal
    # https://x.com/OliverJAsh/status/1963512778808820089
    LESS = "--ignore-case";
  };

  programs.bat = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
    # Avoid cluttering project directories which often conflicts with tooling,
    # as per:
    #   https://github.com/direnv/direnv/wiki/Customizing-cache-location
    stdlib = ''
      : ''${XDG_CACHE_HOME:=$HOME/.cache}
      declare -A direnv_layout_dirs
      direnv_layout_dir() {
      	echo "''${direnv_layout_dirs[$PWD]:=$(
      		echo -n "$XDG_CACHE_HOME"/direnv/layouts/
      		echo -n "$PWD" | ${pkgs.coreutils}/bin/sha1sum | cut -d ' ' -f 1
      	)}"
      }
    '';
  };

  programs.fish = {
    enable = true;

    plugins = [
      {
        name = "fish-completion-sync";
        src = pkgs.fetchFromGitHub {
          owner = "pfgray";
          repo = "fish-completion-sync";
          rev = "ba70b6457228af520751eab48430b1b995e3e0e2";
          sha256 = "sha256-JdOLsZZ1VFRv7zA2i/QEZ1eovOym/Wccn0SJyhiP9hI=";
        };
      }
    ];

    interactiveShellInit = ''
      set --global fish_greeting

      but completions fish | source
    '';

    shellAbbrs = {
      cat = "bat";
      cdg = "cd ~/Dev/gitbutler/";
      cdd = "cd ~/Dev/dotfiles/";
      sh = "nix shell nixpkgs#";
      up = "sudo darwin-rebuild switch --flake ~/Dev/dotfiles/";
    };

    functions = {
      mkcd = "mkdir -p $argv; cd $argv;";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      # scan_timeout = 5;

      character = {
        success_symbol = "λ";
        error_symbol = "!";
      };
      format = "$character";
      right_format = "$direnv$nix_shell$directory$git_branch";

      direnv = {
        disabled = false;
        format = "[$allowed]($style)";
        style = "red";
        allowed_msg = "";
        not_allowed_msg = "? ";
        denied_msg = " ";
      };
      nix_shell = {
        format = "[$symbol]($style)";
        symbol = " ";
      };
    };
  };
}
