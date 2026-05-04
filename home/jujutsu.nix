{
  name,
  email,
  sshSigningKey,
}:
{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    lazyjj

    # https://github.com/davidpdrsn/jj-sync-prs
    jj-ryu
    jj-stack
  ];

  programs.jjui = {
    enable = true;
    settings = {
      # TODO: ? https://github.com/idursun/jjui/commit/1b1aa46dad4d9d96435cfeed63d46c3c559cb5a9
      ui.colors.selected = {
        bg = "#171a1f";
      };

      preview = {
        show_at_start = true;
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
          name = "new-no-edit-after";
          lua = ''
            -- `jj new` outputs new change ID to stderr, but jjui's `jj()`
            -- helper only returns stdout, so we resolve the new change ID with a
            -- follow-up `jj log` query.
            local change = revisions.current()
            jj("new", "--no-edit", "-A", change)

            local created, err = jj(
              "log",
              "-r",
              "children(" .. change .. ")",
              "--limit",
              "1",
              "--no-graph",
              "--template",
              "change_id.shortest()"
            )
            if err then
              flash({ text = err, error = true })
              return
            end

            revisions.refresh({ selected_revision = created })
          '';
        }
        {
          name = "new-no-edit-before";
          lua = ''
            -- `jj new` outputs new change ID to stderr, but jjui's `jj()`
            -- helper only returns stdout, so we resolve the new change ID with a
            -- follow-up `jj log` query.
            local change = revisions.current()
            jj("new", "--no-edit", "-B", change)

            local created, err = jj(
              "log",
              "-r",
              "parents(" .. change .. ")",
              "--limit",
              "1",
              "--no-graph",
              "--template",
              "change_id.shortest()"
            )
            if err then
              flash({ text = err, error = true })
              return
            end

            revisions.refresh({ selected_revision = created })
          '';
        }
        # https://github.com/idursun/jjui/issues/218
        {
          name = "resolve-with";
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
                "combo",
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

            if tool == "combo" then
              local combo_args = { "resolve", "-r", change, "--tool", "mergiraf" }
              if file and file ~= "" then
                table.insert(combo_args, file)
              end

              jj_async(combo_args)

              if file and file ~= "" then
                revisions.details.refresh()
              else
                revisions.refresh({ keep_selections = true, selected_revision = change })
              end

              local out, err = jj("log", "-r", "conflicts() & " .. change, "--no-graph", "-T", "change_id")
              if err then
                flash({ text = err, error = true })
                return
              end
              if out ~= "" then
                local interactive_args = { "resolve", "-r", change }
                if file and file ~= "" then
                  table.insert(interactive_args, file)
                end
                jj_interactive(interactive_args)
              end

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
      ];

      # https://github.com/idursun/jjui/issues/352
      bindings = [
        {
          action = "revisions.inline_describe.accept";
          key = "enter";
          scope = "revisions.inline_describe";
        }
        {
          action = "revisions.inline_describe.new_line";
          key = "shift+enter";
          scope = "revisions.inline_describe";
        }

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
          action = "new-no-edit-after";
          key = "ctrl+a";
          scope = "revisions";
        }
        {
          action = "new-no-edit-before";
          key = "ctrl+b";
          scope = "revisions";
        }
        {
          action = "resolve-with";
          key = "ctrl+c";
          scope = "revisions";
        }
        {
          action = "resolve-with";
          key = "ctrl+c";
          scope = "revisions.details";
        }
        {
          action = "copy-git-diff";
          key = "ctrl+x";
          scope = "revisions";
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
        # TODO: add --sort-paths
        # https://github.com/nix-community/home-manager/blob/1eb0549a1ab3fe3f5acf86668249be15fa0e64f7/modules/programs/difftastic.nix#L166
        diff-formatter = "difft";
        merge-editor = "vscode";
      };
      signing = {
        behavior = "own";
        backend = "ssh";
        key = sshSigningKey;
      };

      merge-tools.difft.program = lib.getExe pkgs.difft-auto-layout;

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

  programs.fish.shellAbbrs.z = "jjui";
}
