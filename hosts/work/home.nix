{ lib, pkgs, ... }:

let
  name = "Oliver Joseph Ash";
  email = "oliverjash@gmail.com";
in
{
  imports = [ ../common/home.nix ];

  home.packages = with pkgs;
    [
      ast-grep
      claude-code
      curl # for Brotli compression support
      difftastic
      jjui
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

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        inherit name email;
      };
      ui = {
        # Until there's a programs.jujutsu.delta.enable option:
        #   https://github.com/nix-community/home-manager/issues/4887
        pager = lib.getExe pkgs.delta;
        diff-formatter = ":git";
        # https://github.com/idursun/jjui/discussions/163#discussioncomment-13672946
        # diff-formatter = lib.getExe pkgs.delta;

        merge-editor = "vscode";
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

          # Disabling this for now because poor syntax highlighting.
          # externalDiffCommand = "difft --color=always";
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
      set --global fish_greeting
    '';

    shellAbbrs = {
      cat = "bat";
      cdw = "cd ~/Dev/unsplash/unsplash-web/";
      cdd = "cd ~/Dev/dotfiles/";
      sh = "nix shell nixpkgs#";
      up = "sudo darwin-rebuild switch --flake ~/Dev/dotfiles/";
      z = "lazygit";
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

  programs.vscode = {
    enable = true;
    # https://github.com/nix-community/home-manager/issues/3375
    package = pkgs.runCommand "dummy" { } "mkdir $out" // {
      pname = pkgs.vscode.pname;
      version = "0.0.0";
    };

    userSettings = {
      # Fixes issue whereby TS server hangs e.g. after running `just typecheck`.
      # Potentially related:
      # - https://github.com/microsoft/vscode/issues/226050
      # - https://github.com/microsoft/vscode/issues/214567
      # - https://github.com/microsoft/vscode/issues/232699
      # - https://github.com/microsoft/vscode/issues/226401
      # - https://github.com/microsoft/vscode/issues/234643
      # Default is "vscode".
      # This setting was previously
      # "typescript.tsserver.experimental.useVsCodeWatcher": false.
      "typescript.tsserver.experimental.useVsCodeWatcher" = false;
      "typescript.tsserver.watchOptions" = {};
      # Alternatively:
      # "files.watcherExclude" = {
      #   # This effectively sets `useVsCodeWatcher` to `false`:
      #   # https://github.com/microsoft/vscode/blob/71d320f7f250d79b4e3e0b5385be0e2ff25f7435/extensions/typescript-language-features/src/configuration/configuration.ts#L232
      #   # "**/node_modules/**" = true;

      #   "**/.turbo/**" = true;
      #   "**/declarations/**" = true;
      #   "**/lang/**" = true;
      #   "**/*.tsbuildinfo" = true;
      # };

      # Else it appears all the time when opening file outside of workspace.
      "biome.suggestInstallingGlobally" = false;
      "copyCodeBlock.formats" = [
        {
          formatName = "markdown";
          codeBlockHeaderFormat = "```\${fileExtnameWithoutDot}\${EOL}";
          codeBlockFooterFormat = "```\${EOL}";
          codeLineFormat = "\${CODE}\${EOL}";
          multipleSelectionCreateMultipleCodeBlocks = false;
          multipleSelectionsBoundalyMarkerFormat = "---\${EOL}";
          forcePathSeparatorSlash = true;
          forceSpaceIndent = true;
        }
        {
          formatName = "markdownWithRelativePath";
          codeBlockHeaderFormat = "`\${workspaceFolderRelativePath}`:\n```\${fileExtnameWithoutDot}\${EOL}";
          codeBlockFooterFormat = "```\${EOL}";
          codeLineFormat = "\${CODE}\${EOL}";
          multipleSelectionCreateMultipleCodeBlocks = false;
          multipleSelectionsBoundalyMarkerFormat = "---\${EOL}";
          forcePathSeparatorSlash = true;
          forceSpaceIndent = true;
        }
      ];
      "editor.autoClosingDelete" = "always";
      "editor.gotoLocation.multipleDefinitions" = "goto";
      "editor.smartSelect.selectSubwords" = false;
      "editor.stickyScroll.enabled" = true;
      "files.insertFinalNewline" = true;
      "files.trimFinalNewlines" = true;
      "files.trimTrailingWhitespace" = true;
      "github.copilot.nextEditSuggestions.enabled" = true;
      "githubPullRequests.pullBranch" = "never";
      "typescript.referencesCodeLens.enabled" = true;
      "window.autoDetectColorScheme" = true;
      "workbench.secondarySideBar.defaultVisibility" = "hidden";
      "workbench.startupEditor" = "none";
    };

    keybindings = [
      {
        key = "alt+j alt+1";
        command = "extension.copyCodeBlock";
        args = {
          formatName = "markdown";
        };
      }
      {
        key = "alt+j alt+2";
        command = "extension.copyCodeBlock";
        args = {
          formatName = "markdownWithRelativePath";
        };
      }
      {
        key = "alt+w";
        command = "editor.action.insertSnippet";
        when = "editorTextFocus";
        args = {
          snippet = "$LINE_COMMENT TODO: ";
        };
      }
      {
        key = "alt+c";
        command = "editor.action.insertSnippet";
        when = "editorTextFocus";
        args = {
          langId = "typescript";
          name = "function call";
        };
      }
      {
        key = "alt+a";
        command = "editor.action.smartSelect.expand";
        when = "editorTextFocus";
      }
      {
        key = "ctrl+shift+right";
        command = "-editor.action.smartSelect.expand";
        when = "editorTextFocus";
      }
      {
        key = "alt+z";
        command = "editor.action.smartSelect.shrink";
        when = "editorTextFocus";
      }
      {
        key = "ctrl+shift+left";
        command = "-editor.action.smartSelect.shrink";
        when = "editorTextFocus";
      }
      {
        key = "alt+s alt+up";
        command = "merge.goToPreviousUnhandledConflict";
      }
      {
        key = "alt+s alt+down";
        command = "merge.goToNextUnhandledConflict";
      }
      {
        key = "ctrl+cmd+b";
        command = "editor.action.codeAction";
        args = {
          kind = "refactor.rewrite.arrow";
        };
      }
      {
        key = "alt+shift+q";
        command = "editor.action.codeAction";
        args = {
          kind = "source.fixAll";
          apply = "first";
        };
      }
      # Misc
      {
        key = "cmd+shift+alt+r";
        command = "runCommands";
        args = {
          commands = [
            "workbench.action.closeAllGroups"
            "workbench.action.closeAuxiliaryBar"
            "workbench.action.closeSidebar"
            "workbench.files.action.collapseExplorerFolders"
            "workbench.action.terminal.killAll"
            "workbench.action.closePanel"
            "workbench.action.clearRecentFiles"
            "workbench.action.reloadWindow"
          ];
        };
      }
      {
        key = "ctrl+alt+;";
        command = "editor.emmet.action.matchTag";
      }
      {
        key = "shift+alt+cmd+l";
        command = "liveshare.start";
      }
      # Most of the time I want to copy a permalink to code on the default branch.
      # My preferred workflow is to use this shortcut to open using the default
      # branch, check the line selection is correct, and then use GitHub's on page
      # shortcut for copying a permalink. The GitHub Pull Requests extension has
      # similar functionality, but it only allows opening as permalink. The current
      # changes may not exist yet on the remote. Related issue:
      # https://github.com/microsoft/vscode-pull-request-github/issues/4765
      {
        key = "shift+cmd+alt+o";
        command = "openInGithub.openInGitHubFile";
      }
    ];

    globalSnippets = {
      "function" = {
        description = "function";
        scope = "javascript,javascriptreact,typescript,typescriptreact";
        prefix = "f";
        body = "(\$1)\$2 => \${3:{ \${4:return \${5:\${SELECTION:null}}} }}";
      };
      "function call" = {
        description = "function call";
        scope = "javascript,javascriptreact,typescript,typescriptreact";
        prefix = "fc";
        body = "\${1:fn}(\${2:\$SELECTION})";
      };
      "destructured const" = {
        description = "destructured const";
        scope = "typescript,typescriptreact,javascript,javascriptreact";
        prefix = "const";
        body = [
          "const { \${2:name} } = \${1:value};"
        ];
      };
      "IIFE" = {
        description = "IIFE";
        scope = "javascript,javascriptreact,typescript,typescriptreact";
        prefix = "iife";
        body = "(() => { \$SELECTION\$1 })()";
      };
      "namespace import" = {
        description = "namespace import";
        scope = "javascript,javascriptreact,typescript,typescriptreact";
        prefix = "impns";
        body = [
          "import * as \${2:Namespace} from '\$1';"
        ];
      };
      "JSX fragment" = {
        description = "JSX fragment";
        scope = "javascript,javascriptreact,typescript,typescriptreact";
        prefix = "frag";
        body = "<>\$SELECTION\$1</>";
      };
      "ternary" = {
        description = "ternary";
        scope = "javascript,javascriptreact,typescript,typescriptreact";
        prefix = "tern";
        body = "\${1:condition} ? \${2:\${SELECTION:{}}} : \${3:{}}";
      };
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

  home.activation.caddy = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sf ~/Dev/dotfiles/hosts/work/proxy/Caddyfile /opt/homebrew/etc/Caddyfile
    /opt/homebrew/bin/brew services start caddy
  '';
}
