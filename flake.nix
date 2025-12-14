{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs =
    inputs@{
      darwin,
      home-manager,
      nixpkgs,
      nix-vscode-extensions,
      ...
    }:
    let
      jjuiOverlay = final: prev: {
        jjui = prev.jjui.overrideAttrs (_old: {
          version = "0.9.8";
          src = prev.fetchFromGitHub {
            owner = "idursun";
            repo = "jjui";
            tag = "v0.9.8";
            hash = "sha256-YEEcSaIm21IUp7EFdYvDG2h55YIqzghYdGxdXmZnp9I=";
          };
          vendorHash = "sha256-2TlJJY/eM6yYFOdq8CcH9l2lFHJmFrihuGwLS7jMwJ0=";
        });
      };

      jjStackOverlay = final: prev: {
        jj-stack = prev.buildNpmPackage rec {
          pname = "jj-stack";
          version = "1.2.1";

          src = prev.fetchFromGitHub {
            owner = "keanemind";
            repo = "jj-stack";
            rev = "v${version}";
            sha256 = "sha256-fk+FZv4lu+noM6ig4NFGAlRy4AWdEjkLIDZZ877bKLs=";
          };

          npmDepsHash = "sha256-RVOnxdzSpgyxfS+EZS1oIlX+chUl8GyLXKrmVlEmLPg=";

          meta = with prev.lib; {
            description = "Stacked PRs on GitHub for Jujutsu";
            homepage = "https://github.com/keanemind/jj-stack";
            license = licenses.mit;
          };
        };
      };
    in
    {
      darwinConfigurations."Olivers-MacBook-Pro" = darwin.lib.darwinSystem {
        modules = [
          ./darwin.nix
          home-manager.darwinModules.home-manager
          {
            nixpkgs.overlays = [
              jjuiOverlay
              jjStackOverlay
              nix-vscode-extensions.overlays.default
            ];

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.oliver = import ./home.nix;
          }
        ];
        specialArgs = { inherit nix-vscode-extensions; };
      };
    };
}
