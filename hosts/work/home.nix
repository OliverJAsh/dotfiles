{ lib, pkgs, ... }:

let
  name = "Oliver Joseph Ash";
  email = "oliverjash@gmail.com";
in
{
  imports = [
    ../common/home.nix
    ../personal/home.nix
  ];

  home.packages = with pkgs;
    [
      ast-grep
      claude-code
      curl # for Brotli compression support
      lazyjj
      nixfmt
    ];

  programs.mergiraf = { enable = true; };

  programs.ghostty = {
    enable = true;
    package = pkgs.runCommand "noop" { meta.mainProgram = "noop"; } "mkdir $out";
    # https://github.com/nix-community/home-manager/pull/6235#issuecomment-2567896192
    installBatSyntax = false;
    settings = {
      macos-option-as-alt = true;
      shell-integration-features = "no-cursor";
    };
  };

  programs.jjui = {
    enable = true;
    settings = {
      leader = {
        # https://idursun.github.io/jjui/Leader-Key.html#edit-a-file-from-revision-detail-idea-from-184
        # https://github.com/idursun/jjui/issues/184#issuecomment-3315056343
        e = {
          context = [ "$file" "$change_id" ];
          help = "Edit file in @";
          # send = [ "$" "$EDITOR $file" "enter" ];
          send = [ "$" "code $file" "enter" ];
        };
        E = {
          context = [ "$file" "$change_id" ];
          help = "Edit file in change";
          # send = [ "$" "jj edit $change_id && $EDITOR $file" "enter" ];
          send = [ "$" "jj edit $change_id && code $file" "enter" ];
        };

        n = {
          context = [ "$change_id" ];
          help = "New change";
        };
        na = {
          context = [ "$change_id" ];
          help = "After";
          # send = [ ":" "new -A $change_id" "enter" "@" ];
          # Faster
          send = [ "ctrl+a" "@" ];
        };
        nb = {
          context = [ "$change_id" ];
          help = "Before";
          # send = [ ":" "new -B $change_id" "enter" "@" ];
          # Faster
          send = [ "ctrl+b" "@" ];
        };
      };
      custom_commands = {
        # https://idursun.github.io/jjui/Custom-Commands.html#new-note-commit-insert-an-empty-commit-inline-after--idea-from-278
        # https://github.com/idursun/jjui/issues/278
        # Or: `nrJa⏎`
        "new after" = {
          key = [ "ctrl+a" ];
          args = [ "new" "-A" "$change_id" ];
        };
        "new before" = {
          key = [ "ctrl+b" ];
          args = [ "new" "-B" "$change_id" ];
        };
        "resolve" = {
          # Conflicts with Revert
          # key = [ "R" ];
          args = [ "resolve" ];
        };
        "resolve mergiraf" = {
          # Conflicts with Revert
          # key = [ "R" ];
          args = [ "resolve" "--tool" "mergiraf" ];
        };
      };
      ui = {
        auto_refresh_interval = 3;
      };
      # Same as default with customised tool. # Prefer inline display due to narrow window.
      preview = {
        revision_command = [ "show" "--color" "always" "-r" "$change_id" "--tool" "difftInline" ];
        file_command = [ "diff" "--color=always" "-r" "$change_id" "$file" "--tool" "difftInline" ];
      };
    };
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        inherit name email;
      };
      ui = {
        # https://difftastic.wilfred.me.uk/jj.html
        diff-formatter = [ "${lib.getExe pkgs.difftastic}" "--color=always" "$left" "$right" ];
        merge-editor = "vscode";
      };
      merge-tools = {
        difftInline = {
          program = lib.getExe pkgs.difftastic;
          diff-args = ["--color=always" "$left" "$right" "--display=inline"];
        };
      };
    };
  };

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

  programs.git = {
    enable = true;

    userName = name;
    userEmail = email;

    # difftastic needs better syntax highlighting.
    # https://github.com/Wilfred/difftastic/issues/541
    # Also: https://github.com/Wilfred/difftastic/issues/304
    difftastic = {
      enable = true;
      enableAsDifftool = true;
      color = "always";
    };

    lfs = { enable = true; };

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
      # Using diff3 instead of zdiff3 because it works better with Mergiraf.
      merge.conflictstyle = "diff3";

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
          # https://github.com/jesseduffield/lazygit/pull/4832#issuecomment-3289371491
          # useExternalDiffGitConfig = true;
          externalDiffCommand = "difft --color=always";
        };

        ignoreWhitespaceInDiffView = true;
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
      set --global fish_greeting
    '';

    shellAbbrs = {
      cat = "bat";
      cdw = "cd ~/Dev/unsplash/unsplash-web/";
      cdd = "cd ~/Dev/dotfiles/";
      sh = "nix shell nixpkgs#";
      up = "sudo darwin-rebuild switch --flake ~/Dev/dotfiles/";
      z = "jjui";
    };

    functions = { mkcd = "mkdir -p $argv; cd $argv;"; };
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
        denied_msg = " ";
      };
      nix_shell = {
        format = "[$symbol]($style)";
        symbol = " ";
      };
    };
  };

  # Storing settings in Nix means they are not writable:
  # https://github.com/nix-community/home-manager/issues/1800
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
            anthropic.claude-code
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
    ln -sf ~/Dev/dotfiles/hosts/work/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
    ln -sf ~/Dev/dotfiles/hosts/work/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
    rm -f ~/Library/Application\ Support/Code/User/snippets
    ln -sf ~/Dev/dotfiles/hosts/work/vscode/snippets ~/Library/Application\ Support/Code/User/snippets
  '';
  home.activation.caddy = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sf ~/Dev/dotfiles/hosts/work/proxy/Caddyfile /opt/homebrew/etc/Caddyfile
    /opt/homebrew/bin/brew services start caddy
  '';
}
