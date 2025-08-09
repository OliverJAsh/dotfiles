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
    inputs@{ darwin, home-manager, nixpkgs, nix-vscode-extensions, ... }: {
      darwinConfigurations."Olivers-MacBook-Pro" = darwin.lib.darwinSystem {
        modules = [
          ./hosts/work/darwin.nix
          home-manager.darwinModules.home-manager
          {
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
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.oliver = import ./hosts/personal/home.nix;
          }
        ];
      };
    };
}
