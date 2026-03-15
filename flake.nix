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
                kajji = prev.callPackage ./pkgs/kajji.nix { };
              })
              (final: prev: {
                jj-ryu = prev.callPackage ./pkgs/jj-ryu.nix { };
              })
              (final: prev: {
                weave = prev.callPackage ./pkgs/weave.nix { };
              })
              (final: prev: {
                jjui = prev.jjui.overrideAttrs (old: rec {
                  version = "0.10.0";
                  src = prev.fetchFromGitHub {
                    owner = "idursun";
                    repo = "jjui";
                    tag = "v${version}";
                    hash = "sha256-wGal1aulnbacP6Ovms82XKPMbUvH/rs9Rg/B40E3uls=";
                  };
                  vendorHash = "sha256-egPW+YgRkdOdnzei5J2JmSt/98fpoo1lphsoQIK41Lg=";
                });
              })
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
