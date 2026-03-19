{ lib, pkgs, ... }:

let
  name = "Oliver Joseph Ash";
  email = "oliverjash@gmail.com";
  sshSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILVN8hEG4Z4si/JTl+L9b1f2npLjZ9gQ0DW1op6HLaT9";
  # https://github.com/Wilfred/difftastic/issues/693
  jjDifft = pkgs.writeShellApplication {
    name = "jj-difft";
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
        width="$(tput cols)"
      fi

      if [ "$width" -lt 140 ]; then
        display=inline
      else
        display=side-by-side
      fi

      exec difft --display "$display" "$@"
    '';
  };
  # https://github.com/dandavison/delta/issues/359
  # https://github.com/dandavison/delta/issues/2083
  jjDelta = pkgs.writeShellApplication {
    name = "jj-delta";
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
        width="$(tput cols)"
      fi

      if [ "$width" -ge 140 ]; then
        exec delta --side-by-side "$@"
      fi

      exec delta "$@"
    '';
  };
in
{
  home.username = "oliver";
  home.homeDirectory = "/Users/oliver";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ast-grep
    claude-code
    colima
    curl # for Brotli compression support
    delta
    gh
    kajji
    lazyjj
    # Not using `programs.mergiraf` due to https://github.com/gitbutlerapp/gitbutler/issues/10509
    mergiraf
    nixfmt
    ripgrep

    # https://github.com/davidpdrsn/jj-sync-prs
    jj-ryu
    jj-stack
  ];

  home.file.".config/kajji/config.json".text = ''
    {
      "ui": {
        "showFileTree": false
      },
      "diff": {
        "useJjFormatter": true
      }
    }
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        addKeysToAgent = "yes";
        identityFile = "~/.ssh/id_ed25519";
        extraOptions = {
          UseKeychain = "yes";
        };
      };
    };
  };

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
      # TODO: ? https://github.com/idursun/jjui/commit/1b1aa46dad4d9d96435cfeed63d46c3c559cb5a9
      ui.colors.selected = {
        bg = "#171a1f";
      };

      # jj passes the terminal width through to diff commands, but for jjui's
      # preview that terminal width is the outer terminal (or a default), not
      # the width of jjui's internal preview pane. jjui exposes the actual pane
      # width as `$preview_width`, so we override the preview commands to pass
      # that value through explicitly. Ideally this wouldn't be necessary:
      # https://github.com/idursun/jjui/pull/608
      preview = {
        revision_command = [
          "--config=merge-tools.difft.diff-args=[\"--color=always\",\"--width=$preview_width\",\"$left\",\"$right\"]"
          "--config=merge-tools.delta.diff-args=[\"--tabs=2\",\"--width=$preview_width\",\"$left\",\"$right\"]"
          "show"
          "--color"
          "always"
          "-r"
          "$change_id"
        ];
        file_command = [
          "--config=merge-tools.difft.diff-args=[\"--color=always\",\"--width=$preview_width\",\"$left\",\"$right\"]"
          "--config=merge-tools.delta.diff-args=[\"--tabs=2\",\"--width=$preview_width\",\"$left\",\"$right\"]"
          "diff"
          "--color"
          "always"
          "-r"
          "$change_id"
          "$file"
        ];
      };

      actions = [
        {
          name = "pr";
          lua = ''
            jj_async("pr", context.change_id())
          '';
        }
        # https://idursun.github.io/jjui/lua-cookbook/#incrementally-expand-ancestors-in-the-revset
        {
          name = "append-ancestors-to-revset";
          lua = ''
            local change_id = revisions.current()
            if not change_id then
              return
            end

            local current = revset.current()
            local bumped = false
            local updated = current:gsub("ancestors%(" .. change_id .. "%s*,%s*(%d+)%)", function(n)
              bumped = true
              return "ancestors(" .. change_id .. ", " .. (tonumber(n) + 1) .. ")"
            end, 1)

            if not bumped then
              updated = current .. " | ancestors(" .. change_id .. ", 2)"
            end

            revset.set(updated)
          '';
        }
        {
          name = "edit-file";
          lua = ''
            local f = context.file()
            if not f then
              return
            end
            jj_async("util", "exec", "--", "code", f)
          '';
        }
        # https://github.com/idursun/jjui/issues/310
        # https://github.com/idursun/jjui/pull/422
        {
          name = "inline-commit";
          lua = ''
            revisions.open_inline_describe()
            if wait_close() then
              jj("new", revisions.current())
            end
          '';
        }
        {
          name = "new-after";
          lua = ''
            jj("new", "-A", revisions.current())
            revisions.refresh()
            revisions.navigate { to = "@" }
          '';
        }
        {
          name = "new-before";
          lua = ''
            jj("new", "-B", revisions.current())
            revisions.refresh()
            revisions.navigate { to = "@" }
          '';
        }
        # https://github.com/idursun/jjui/issues/218
        {
          name = "resolve-combo";
          lua = ''
            local change = context.change_id()
            jj_async("resolve", "-r", change, "--tool", "mergiraf")
            revisions.refresh({ keep_selections = true, selected_revision = change })
            local out, err = jj("log", "-r", "conflicts() & " .. change, "--no-graph", "-T", "change_id")
            if err then
              flash({ text = err, error = true })
              return
            end
            if out ~= "" then
              jj_interactive("resolve", "-r", change)
            end
          '';
        }
        {
          name = "resolve";
          lua = ''
            local change = context.change_id()
            if not change or change == "" then
              flash({ text = "No change selected", error = true })
              return
            end

            local file = context.file()
            local tool = choose({
              title = "Resolve with",
              options = {
                "vscode",
                "mergiraf",
                "weave",
                ":ours",
                ":theirs",
              },
              ordered = true,
            })
            if not tool then
              return
            end

            local args = { "resolve", "-r", change, "--tool", tool }
            if file and file ~= "" then
              table.insert(args, file)
            end

            if tool == "vscode" then
              jj_interactive(args)
            else
              jj_async(args)
            end

            if file and file ~= "" then
              revisions.details.refresh()
            else
              revisions.refresh({ keep_selections = true, selected_revision = change })
            end
          '';
        }
        {
          name = "copy-git-diff";
          lua = ''
            local out, err = jj("show", "--git", context.change_id())
            if err then
              flash({ text = err, error = true })
              return
            end
            local ok, copy_err = copy_to_clipboard(out)
            if not ok then
              flash({ text = copy_err, error = true })
            end
          '';
        }
        # https://github.com/idursun/jjui/issues/587
        # https://github.com/idursun/jjui/issues/218
        {
          name = "diff.with";
          lua = ''
            local change = context.change_id()
            if not change or change == "" then
              flash({ text = "No change selected", error = true })
              return
            end

            local file = context.file()
            local tool = choose({
              title = "Diff with",
              options = {
                "default",
                "difft",
                "delta",
                ":git",
                ":color-words",
                ":summary",
                ":stat",
                ":types",
                ":name-only",
              },
              ordered = true,
            })
            if not tool then
              return
            end

            local args
            if file and file ~= "" then
              args = { "diff", "-r", change }
            else
              args = { "show", "-r", change }
            end

            if tool ~= "default" then
              table.insert(args, "--tool")
              table.insert(args, tool)
            end

            if file and file ~= "" then
              table.insert(args, file)
            end

            local out, err = jj(args)
            if err then
              flash({ text = err, error = true })
              return
            end

            jjui.diff.show(out)
          '';
        }
        {
          name = "toggle-parent";
          lua = ''
            jj_async("toggle-parent", context.change_id())
          '';
        }
        {
          name = "rebase-onto-trunk";
          lua = ''
            jj_async("rebase", "--onto", "trunk()")
            revisions.refresh({ keep_selections = true, selected_revision = context.change_id() })
          '';
        }
        {
          name = "diff.select-formatter";
          lua = ''
            local current, err = jj("config", "get", "ui.diff-formatter")
            if err then
              flash({ text = err, error = true })
              return
            end

            current = current:gsub("%s+$", "")

            local formatter = choose({
              title = "Diff formatter (current: " .. current .. ")",
              options = {
                "difft",
                "delta",
              },
              ordered = true,
            })
            if not formatter then
              return
            end

            if formatter == current then
              flash("Diff formatter: " .. formatter)
              return
            end

            local _, set_err = jj("config", "set", "--repo", "ui.diff-formatter", formatter)
            if set_err then
              flash({ text = set_err, error = true })
              return
            end

            local change = context.change_id()
            local file = context.file()
            if file then
              revisions.details.refresh()
              revisions.details.select_file(file)
            else
              revisions.refresh({ keep_selections = true, selected_revision = change })
              if change and change ~= "" then
                revisions.navigate({ to = change, ensureView = true })
              end
            end

            jjui.ui.preview_toggle()
            jjui.ui.preview_toggle()

            flash("Diff formatter: " .. formatter)
          '';
        }
      ];

      # https://github.com/idursun/jjui/issues/352
      bindings = [
        {
          action = "revisions.commit";
          key = "C";
          scope = "revisions";
        }
        {
          action = "pr";
          seq = [
            "w"
            "p"
          ];
          scope = "revisions";
        }
        {
          action = "append-ancestors-to-revset";
          key = "+";
          scope = "revisions";
        }
        {
          action = "edit-file";
          seq = [
            "w"
            "e"
          ];
          scope = "revisions.details";
        }
        {
          action = "inline-commit";
          key = "c";
          scope = "revisions";
        }
        {
          action = "new-after";
          key = "ctrl+a";
          scope = "revisions";
        }
        {
          action = "new-before";
          key = "ctrl+b";
          scope = "revisions";
        }
        {
          action = "resolve";
          key = "ctrl+c";
          scope = "revisions";
        }
        {
          action = "resolve";
          key = "ctrl+c";
          scope = "revisions.details";
        }
        {
          action = "resolve-combo";
          key = "ctrl+shift+c";
          scope = "revisions";
        }
        {
          action = "copy-git-diff";
          key = "ctrl+x";
          scope = "revisions";
        }
        {
          action = "diff.with";
          desc = "diff with...";
          seq = [
            "w"
            "d"
            "d"
          ];
          scope = "revisions";
        }
        {
          action = "diff.with";
          desc = "diff with...";
          seq = [
            "w"
            "d"
            "d"
          ];
          scope = "revisions.details";
        }
        {
          action = "diff.select-formatter";
          desc = "select diff formatter";
          seq = [
            "w"
            "d"
            "f"
          ];
          scope = "revisions";
        }
        {
          action = "diff.select-formatter";
          desc = "select diff formatter";
          seq = [
            "w"
            "d"
            "f"
          ];
          scope = "revisions.details";
        }
        {
          action = "toggle-parent";
          key = "ctrl+p";
          scope = "revisions";
        }
        {
          action = "rebase-onto-trunk";
          seq = [
            "w"
            "r"
            "t"
          ];
          scope = "revisions";
        }
      ];
    };
  };

  programs.jujutsu = {
    enable = true;

    settings = {
      user = {
        inherit name email;
      };
      revset-aliases = {
        # https://github.com/samhh/dotfiles/blob/e1479cab9e068542db1c840b93335ca0cfa07221/home/vcs.nix#L62-L79
        "anon()" = "stack(mine() ~ ::remote_bookmarks(), 1)";
        "here()" = "stack(@, 1)";
        # https://github.com/jj-vcs/jj/discussions/7588#discussioncomment-14832469
        "mega()" = "heads(merges() & ::@)";
        "null()" = "empty() & description(exact:'')";
        "open()" = "stack(mine() | @, 1)";
        "ready()" = "open() ~ stack(wip(), 1)";
        "stack()" = "stack(@)";
        "stack(x)" = "stack(x, 2)";
        "stack(x, n)" = "ancestors(reachable(x, mutable()), n)";
        "symdiff(x, y)" = "(x ~ y) | (y ~ x)";
        "toggle(x)" = "toggle(mega(), x)";
        "toggle(x, y)" = "symdiff(parents(x), y)";
        "wip()" = "null() | description(regex:\"^[A-Z]+:\")";

        # https://github.com/jj-vcs/jj/blob/v0.37.0/cli/src/config/revsets.toml#L10
        "log_default()" = "present(@) | ancestors(immutable_heads().., 2) | present(trunk())";

        "closest_bookmark(to)" = "heads(::to & bookmarks())";
      };
      revsets.log = "here()";
      aliases = {
        pr = [
          "util"
          "exec"
          "--"
          "bash"
          "-c"
          ''
            set -euo pipefail

            rev="''${1:-@}"

            head="$(jj log -r "$rev" --no-graph -T bookmarks | awk '{print $1}')"
            [ -n "$head" ] || exit 0

            base="$(jj log -n 1 -r "closest_bookmark($rev-) ~ ::trunk()" --no-graph -T bookmarks | awk '{print $1}')"

            if [ -n "$base" ]; then
              gh pr create --web --head "$head" --base "$base"
            else
              gh pr create --web --head "$head"
            fi
          ''
          "--"
        ];
        toggle-parent = [
          "util"
          "exec"
          "--"
          "bash"
          "-c"
          ''
            set -euo pipefail
            rev="$1"
            jj rebase -r @ -d "(parents(@) | $rev) ~ (parents(@) & $rev)"
          ''
          "--"
        ];
      };
      ui = {
        default-command = [ "log" ];
        diff-formatter = "difft";
        merge-editor = "vscode";
      };
      signing = {
        behavior = "own";
        backend = "ssh";
        key = sshSigningKey;
      };

      merge-tools.delta = {
        program = lib.getExe jjDelta;
        diff-args = [
          "--tabs=2"
          "--width=$width"
          "$left"
          "$right"
        ];
        diff-expected-exit-codes = [
          0
          1
        ];
      };

      merge-tools.difft.program = lib.getExe jjDifft;

      # Same as default minus `--fast`.
      # https://github.com/jj-vcs/jj/wiki/Diff-and-merge-tools#mergiraf
      merge-tools.mergiraf = {
        program = "${lib.getExe pkgs.mergiraf}";
        merge-args = [
          "merge"
          "$base"
          "$left"
          "$right"
          "-o"
          "$output"
          "-l"
          "$marker_length"
        ];
        merge-conflict-exit-codes = [ 1 ];
      };

      # https://github.com/jj-vcs/jj/wiki/Diff-and-merge-tools#weave
      # https://github.com/jj-vcs/jj/pull/8833
      merge-tools.weave = {
        program = "/opt/homebrew/bin/weave-driver";
        merge-args = [
          "$base"
          "$left"
          "$right"
          "-o"
          "$output"
          "-l"
          "$marker_length"
          "-p"
          "$path"
        ];
        merge-conflict-exit-codes = [ 1 ];
        merge-tool-edits-conflict-markers = true;
        conflict-marker-style = "git";
      };
    };
  };

  home.sessionVariables = {
    # Issue: `code` is slow to open files and temporarily opens duplicate
    # VS Code instance in the dock https://github.com/microsoft/vscode/issues/139634
    EDITOR = "code --wait";
    # TODO: -FRX
    # https://stackoverflow.com/questions/32469204/scrolling-down-git-diff-from-mac-terminal
    # https://x.com/OliverJAsh/status/1963512778808820089
    LESS = "--ignore-case";
  };

  programs.difftastic = {
    # - needs better syntax highlighting https://github.com/Wilfred/difftastic/issues/541
    # - missing function names in hunk headers https://github.com/Wilfred/difftastic/issues/304

    enable = true;
    git.diffToolMode = true;
    options = {
      color = "always";
    };
  };

  programs.git = {
    enable = true;

    lfs = {
      enable = true;
    };

    signing.signByDefault = true;
    signing.key = sshSigningKey;

    settings = {
      gpg.format = "ssh";

      user = {
        name = name;
        email = email;
      };

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

      "mergetool \"code\"".cmd = "code --wait --merge $REMOTE $LOCAL $BASE $MERGED";
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

    ignores = [
      ".envrc"
      ".DS_Store"
    ];
  };

  programs.lazygit = {
    enable = true;

    settings = {
      customCommands = [
        {
          key = "<c-n>";
          context = "localBranches";
          command = "gh pr merge --delete-branch --merge {{.SelectedLocalBranch.Name}}";
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
              command = "git format-patch --stdout {{.SelectedCommitRange.From}}^..{{.SelectedCommitRange.To}} | pbcopy";
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
        branchLogCmd = "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium --oneline {{branchName}} --";

        pagers = [
          {
            # https://github.com/jesseduffield/lazygit/pull/4832#issuecomment-3289371491
            # useExternalDiffGitConfig = true;
            externalDiffCommand = "difft --color=always";
          }
        ];

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
      cdg = "cd ~/Dev/gitbutler/";
      cdd = "cd ~/Dev/dotfiles/";
      sh = "nix shell nixpkgs#";
      up = "sudo darwin-rebuild switch --flake ~/Dev/dotfiles/";
      z = "jjui";
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
        extensions = with pkgs.vscode-marketplace; [
          ast-grep.ast-grep-vscode
          cardinal90.multi-cursor-case-preserve
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
    rm -f ~/Library/Application\ Support/Code/User/snippets
    ln -sf ~/Dev/dotfiles/vscode/snippets ~/Library/Application\ Support/Code/User/snippets
  '';
  home.activation.caddy = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sf ~/Dev/dotfiles/proxy/Caddyfile /opt/homebrew/etc/Caddyfile
    /opt/homebrew/bin/brew services start caddy
  '';
}
