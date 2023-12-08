{ pkgs, nix-vscode-extensions, ... }:

{
  home.username = "oliver";
  home.homeDirectory = "/Users/oliver";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    # CLIs
    ast-grep
    difftastic
    duti
    fishPlugins.github-copilot-cli-fish
    fzf
    gh
    github-copilot-cli
    jq
    nixpkgs-fmt

    nodePackages.fkill-cli
    # TODO:
    # nodePackages.trash-cli
  ];

  home.sessionVariables = {
    EDITOR = "code --wait";
    LESS = "--ignore-case";
  };

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;

    userName = "Oliver Joseph Ash";
    userEmail = "oliverjash@gmail.com";

    # difftastic:
    # - https://github.com/nix-community/home-manager/issues/3140

    lfs = {
      enable = true;
    };

    delta = {
      enable = true;
      options = {
        # [ref:color-theme]
        syntax-theme = "Visual Studio Dark+";
        side-by-side = true;
        # Default is 2, after which the line is truncated meaning it won't be
        # visible/accessible.
        wrap-max-lines = 40;
        max-line-distance = 1;
      };
    };

    extraConfig = {
      # TODO:
      # https://withblue.ink/2020/05/17/how-and-why-to-sign-git-commits.html
      # https://jeppesen.io/git-commit-sign-nix-home-manager-ssh/
      # https://blog.1password.com/git-commit-signing/
      # https://developer.1password.com/docs/ssh/git-commit-signing
      # commit.gpgSign = true;
      # tag.gpgSign = true;
      # gpg.format = "ssh";
      # user.signingkey = "";

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
      merge.conflictstyle = "zdiff3";

      mergetool.keepBackup = false;

      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
    };

    ignores = [
      ".direnv/"
      ".envrc"
    ];
  };

  programs.lazygit = {
    enable = true;

    # Build lazygit from latest source whilst we wait for a new release (for
    # Difftastic + commit co-authors).
    package = pkgs.lazygit.overrideAttrs (_: {
      src = pkgs.fetchFromGitHub {
        owner = "jesseduffield";
        repo = "lazygit";
        rev = "ccb1ee0";
        hash = "sha256-VtsIv6tGupe09g+ddeiXzpxY76THy9zRMnDOidZ6h1s=";
      };
    });

    settings = {
      customCommands = [{
        key = "<space>";
        context = "localBranches";
        command = "git checkout {{.SelectedLocalBranch.Name }} && (yarn || true)";
      }];

      git = {
        # Override default to add `--oneline`. Default here:
        # https://github.com/jesseduffield/lazygit/blob/c390c9d58edc18083ed7f1a672b03b7c4d982c12/docs/Config.md
        branchLogCmd = "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium --oneline {{branchName}} --";

        paging = {
          # https://github.com/jesseduffield/lazygit/blob/master/docs/Custom_Pagers.md#delta
          colorArg = "always";
          pager = "delta --dark --paging=never";

          externalDiffCommand = "difft --color=always";
        };
      };

      gui = {
        # Reduce a little to make more room for the main panel.
        sidePanelWidth = 0.2;

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
    };
  };

  # https://github.com/nix-community/nix-direnv#via-home-manager
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.bat = {
    enable = true;
    config = {
      # [ref:color-theme]
      theme = "Visual Studio Dark+";
    };
  };

  programs.fish = {
    enable = true;

    plugins = [
      # https://alexpearce.me/2021/07/managing-dotfiles-with-nix/#fish-shell:~:text=My%20final%20tweak%20was%20to%20include%20iTerm2%E2%80%99s%20shell%20integration%20as%20a%20fish%20plugin
      {
        name = "iterm2-shell-integration";
        src = ./config/iterm2/iterm2_shell_integration;
      }
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
      # https://github.com/direnv/direnv/issues/68
      # https://stackoverflow.com/questions/51349012/stop-direnv-showing-all-environment-variables-on-load
      export DIRENV_LOG_FORMAT=

      iterm2_shell_integration

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
      "cat" = "bat";
      "z" = "lazygit";

      "up" = "nix run nix-darwin -- switch --flake ~/Code/dotfiles/";
    };

    functions = {
      mkcd = "mkdir -p $argv; cd $argv;";
    };
  };

  # TODO: conditionally enable extensions for individual workspaces/projects
  # https://github.com/microsoft/vscode/issues/40239
  # https://code.visualstudio.com/docs/editor/profiles
  programs.vscode = {
    enable = true;
    extensions = with nix-vscode-extensions.extensions.aarch64-darwin.vscode-marketplace; [
      dbaeumer.vscode-eslint
      dbankier.vscode-quick-select
      esbenp.prettier-vscode
      github.copilot
      github.vscode-pull-request-github
      jnoortheen.nix-ide
      matsuyanagi.copy-code-block
      mikestead.dotenv
      ms-playwright.playwright
      ms-vsliveshare.vsliveshare
      orta.vscode-jest
      p42ai.refactor
      stkb.rewrap
      streetsidesoftware.code-spell-checker
      tamasfe.even-better-toml
      timonwong.shellcheck
      wmaurer.change-case
    ];
  };
}
