{ lib, pkgs, ... }:

let
  name = "Oliver Joseph Ash";
  email = "oliverjash@gmail.com";
  sshSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILVN8hEG4Z4si/JTl+L9b1f2npLjZ9gQ0DW1op6HLaT9";
in
{
  imports = [
    (import ./git.nix {
      inherit name email sshSigningKey;
    })
    (import ./jujutsu.nix {
      inherit name email sshSigningKey;
    })
    ./shell.nix
    ./vscode.nix
  ];

  home.username = "oliver";
  home.homeDirectory = "/Users/oliver";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ast-grep
    claude-code
    colima
    curl # for Brotli compression support
    gh
    # Not using `programs.mergiraf` due to https://github.com/gitbutlerapp/gitbutler/issues/10509
    mergiraf
    nixfmt
    ripgrep
  ];

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

  programs.difftastic = {
    # - needs better syntax highlighting https://github.com/Wilfred/difftastic/issues/541
    # - missing function names in hunk headers https://github.com/Wilfred/difftastic/issues/304

    enable = true;
    git.enable = true;
    git.diffToolMode = true;
    # https://github.com/jj-vcs/jj/blob/ac7a8671916ec2082288adf5c13f642041a5f716/cli/src/config/merge_tools.toml#L23
    # jujutsu.enable = true;
    options = {
      tab-width = 2;
    };
  };
}
