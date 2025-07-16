{ lib, pkgs, ... }: {
  home.username = "oliver";
  home.homeDirectory = "/Users/oliver";

  home.stateVersion = "25.05";

  home.packages = with pkgs;
    [
      ast-grep
      difftastic
      nixfmt
    ];

  programs.gh = {
    enable = true;
    extensions = [
      pkgs.gh-copilot
    ];
  };

  home.sessionVariables = {
    # Issue: `code` temporarily opens duplicate VS Code instance in the dock https://github.com/microsoft/vscode/issues/139634
    EDITOR = "code --wait";
    LESS = "--ignore-case";
  };

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;

    userName = "Oliver Joseph Ash";
    userEmail = "oliverjash@gmail.com";

    difftastic.enableAsDifftool = true;

    lfs = { enable = true; };

    delta = {
      enable = true;
      options = {
        side-by-side = true;
        # Default is 2, after which the line is truncated meaning it won't be
        # visible/accessible.
        wrap-max-lines = "unlimited";
      };
    };

    extraConfig = {
      stash.showIncludeUntracked = true;

      init.defaultBranch = "main";

      push = {
        autoSetupRemote = true;
        default = "current";
      };

      # This adds a diff to the commit message template. This is a useful
      # reminder when writing commit messages, and also powers IDE
      # suggestions/completion.
      commit.verbose = true;

      rerere.enabled = true;

      "mergetool \"code\"".cmd =
        "code --wait --merge $REMOTE $LOCAL $BASE $MERGED";
      merge.tool = "code";
      merge.conflictstyle = "zdiff3";

      mergetool.keepBackup = false;

      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
    };

    ignores = [ ".envrc" ".DS_Store" ];
  };

  programs.lazygit = {
    enable = true;

    settings = {
      customCommands = [
        {
          key = "<c-n>";
          context = "localBranches";
          command =
            "gh pr merge --delete-branch --merge {{.SelectedLocalBranch.Name}}";
        }
        {
          key = "E";
          context = "global";
          command = "code {{.SelectedWorktree.Path}}";
        }

        # https://github.com/jesseduffield/lazygit/issues/3396#issuecomment-2995028974
        {
          key = "X";
          description = "Commits clipboard";
          commandMenu = [
            {
              key = "c";
              command =
                "git format-patch --stdout {{.SelectedCommitRange.From}}^..{{.SelectedCommitRange.To}} | pbcopy";
              context = "commits, subCommits";
              description = "Copy selected commits to clipboard";
            }
            {
              key = "v";
              command = "pbpaste | git am";
              context = "commits";
              description = "Paste selected commits from clipboard";
            }
          ];
        }
      ];

      git = {
        overrideGpg = true;

        # Override default to add `--oneline`. Default here:
        # https://github.com/jesseduffield/lazygit/blob/c390c9d58edc18083ed7f1a672b03b7c4d982c12/docs/Config.md
        branchLogCmd =
          "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium --oneline {{branchName}} --";

        paging = {
          # https://github.com/jesseduffield/lazygit/blob/master/docs/Custom_Pagers.md#delta
          colorArg = "always";
          pager = ''
            delta --dark --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"'';
          # https://github.com/jesseduffield/lazygit/blob/master/docs/Custom_Pagers.md#using-external-diff-commands

          # Disabling this for now because:
          # - snapshot diffs are hard to read
          # - very slow in some cases e.g. snapshots
          # - poor syntax highlighting
          # - lazygit needs a command/shortcut to toggle on/off
          externalDiffCommand = "difft --color=always";
        };
      };

      gui = {
        # Reduce a little to make more room for the main panel.
        sidePanelWidth = 0.2;
        # Wishlist: halfSidePanelWidth https://github.com/jesseduffield/lazygit/issues/3054
        expandFocusedSidePanel = true;

        showCommandLog = false;

        theme = {
          # Workaround for https://github.com/jesseduffield/lazygit/issues/750
          selectedLineBgColor = [ "reverse" ];
          selectedRangeBgColor = [ "reverse" ];
        };

        # The default is "flexible". We don't ever want "horizontal" layout
        # because it conflicts with side-by-side diffs.
        mainPanelSplitMode = "vertical";

        showFileTree = false;
      };

      promptToReturnFromSubprocess = false;
    };
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

  programs.bat = {
    enable = true;
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
      # Easy printing with foreground and background colors
      function prompt_segment
        set -l bg $argv[1]
        set -l fg $argv[2]

        set_color -b $bg
        set_color $fg

        if [ -n "$argv[3]" ]
          echo -n -s $argv[3]
        end
      end

      function spacer
        prompt_segment normal normal " "
      end

      # Display status if previous command returned an error
      function show_status
        if [ $RETVAL -ne 0 ]
          prompt_segment normal red "!"
          spacer
        end
      end

      function show_pwd
        prompt_segment normal normal (prompt_pwd)
      end

      # TODO: show name of nix shell e.g. #prod-ops
      # The `$IN_NIX_SHELL` environment variable isn't set in a `nix shell` proper,
      # hence this workaround of checking the `$PATH`.
      #   https://discourse.nixos.org/t/in-nix-shell-env-variable-in-nix-shell-versus-nix-shell/15933
      #   https://github.com/NixOS/nix/issues/3862#issuecomment-707320241
      function is_nix_shell
        echo $PATH | grep -q /nix/store
      end

      function show_prompt
        if is_nix_shell
          prompt_segment normal normal "λ"
        else
          prompt_segment normal normal "\$"
        end
      end

      function fish_prompt
        set -g RETVAL $status
        show_pwd
        fish_git_prompt
        spacer
        show_status
        show_prompt
        spacer
      end

      set --global fish_greeting
    '';

    shellAbbrs = {
      cat = "bat";
      z = "lazygit";
      sh = "nix shell nixpkgs#";
      up = "sudo darwin-rebuild switch --flake ~/Dev/dotfiles/";
    };

    functions = { mkcd = "mkdir -p $argv; cd $argv;"; };
  };

  programs.vscode = {
    enable = true;
    # https://github.com/nix-community/home-manager/issues/3375
    package = pkgs.runCommand "dummy" { } "mkdir $out" // {
      pname = pkgs.vscode.pname;
      version = "0.0.0";
    };
    profiles = {
      default = {
        extensions = with pkgs.vscode-marketplace;
          [
            ast-grep.ast-grep-vscode
            dbankier.vscode-quick-select
            jnoortheen.nix-ide
            matsuyanagi.copy-code-block
            stkb.rewrap
            sysoev.vscode-open-in-github
          ];
      };
    };
  };

  home.activation.vscode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sf ~/Dev/dotfiles/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
    ln -sf ~/Dev/dotfiles/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
    ln -sf ~/Dev/dotfiles/vscode/snippets/ ~/Library/Application\ Support/Code/User/snippets
  '';
  home.activation.caddy = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sf ~/Dev/dotfiles/proxy/Caddyfile /opt/homebrew/etc/Caddyfile
    /opt/homebrew/bin/brew services start caddy
  '';

}
