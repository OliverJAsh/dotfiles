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
    {
      darwinConfigurations."Olivers-MacBook-Pro" = darwin.lib.darwinSystem {
        modules = [
          ./darwin.nix
          home-manager.darwinModules.home-manager
          {
            nixpkgs.overlays = [
              (final: prev: {
                jj-stack = prev.callPackage ./pkgs/jj-stack.nix { };
              })
              (final: prev: {
                jj-ryu = prev.callPackage ./pkgs/jj-ryu.nix { };
              })
              (final: prev: {
                # https://github.com/NixOS/nixpkgs/pull/500629
                difftastic = prev.callPackage ./pkgs/difftastic.nix { };
              })
              (final: prev: {
                difft-auto-layout = prev.callPackage ./pkgs/difft-auto-layout.nix { };
              })
              (final: prev: {
                jjui = prev.jjui.overrideAttrs (old: rec {
                  version = "0.10.4";
                  src = prev.fetchFromGitHub {
                    owner = "idursun";
                    repo = "jjui";
                    tag = "v${version}";
                    hash = "sha256-20NWoojFBwHs33NFNeZbk1kiZ418kYD42XTUOHuQtv8=";
                  };
                  vendorHash = "sha256-AJlJ9iHkkWNS8a4oGt8AG89StjMH9UH3WuOcZwa3VS8=";
                });
              })
              nix-vscode-extensions.overlays.default
            ];

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.oliver = import ./home;
          }
        ];
        specialArgs = { inherit nix-vscode-extensions; };
      };
    };
}
