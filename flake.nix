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
