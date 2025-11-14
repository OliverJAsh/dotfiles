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
    in
    {
      darwinConfigurations."Olivers-MacBook-Pro" = darwin.lib.darwinSystem {
        modules = [
          ./hosts/work/darwin.nix
          home-manager.darwinModules.home-manager
          {
            nixpkgs.overlays = [ jjuiOverlay ];

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.oliver = import ./hosts/work/home.nix;
          }
        ];
        specialArgs = { inherit nix-vscode-extensions; };
      };

      darwinConfigurations."Olivers-MacBook-Pro-Personal" = darwin.lib.darwinSystem {
        modules = [
          ./hosts/personal/darwin.nix
          home-manager.darwinModules.home-manager
          {
            nixpkgs.overlays = [ jjuiOverlay ];

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.oliver = import ./hosts/personal/home.nix;
          }
        ];
      };
    };
}
