{
  lib,
  pkgs,
  nix-vscode-extensions,
  ...
}:

{
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
}
