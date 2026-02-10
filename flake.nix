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
      kajjiOverlay = final: prev: {
        kajji = prev.stdenvNoCC.mkDerivation rec {
          pname = "kajji";
          version = "0.9.0";

          src = prev.fetchurl {
            url = "https://github.com/eliaskc/kajji/releases/download/v${version}/kajji-darwin-arm64.zip";
            sha256 = "sha256-I7N1gOVos/jWOWaq++56eaqfaYfXV5FCb1E0jCAHHx4=";
          };

          nativeBuildInputs = [ prev.unzip ];
          dontUnpack = true;

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            tmp="$(mktemp -d)"
            unzip -q "$src" -d "$tmp"
            install -m755 "$tmp/kajji" "$out/bin/kajji"
            runHook postInstall
          '';

          meta = with prev.lib; {
            description = "A simple jj TUI for local code review and day-to-day jj usage";
            homepage = "https://github.com/eliaskc/kajji";
            license = licenses.mit;
            mainProgram = "kajji";
            platforms = [ "aarch64-darwin" ];
          };
        };
      };
      jjRyuOverlay = final: prev: {
        jj-ryu = prev.rustPlatform.buildRustPackage rec {
          pname = "jj-ryu";
          version = "0.0.1-alpha.11";

          src = prev.fetchFromGitHub {
            owner = "dmmulroy";
            repo = "jj-ryu";
            rev = "v${version}";
            hash = "sha256-gE4lvqyC2LRAWNDUGePklORWjyEofs/dHLHVBAub424=";
          };

          cargoLock = {
            lockFile = "${src}/Cargo.lock";
          };
          cargoHash = prev.lib.fakeHash;

          # tests require `jj` in PATH; nix build sandbox doesn't have it
          doCheck = false;

          meta = with prev.lib; {
            description = "Stacked PRs for Jujutsu (push bookmark stacks to GitHub/GitLab as chained PRs)";
            homepage = "https://github.com/dmmulroy/jj-ryu";
            license = licenses.mit;
            mainProgram = "ryu";
            platforms = [ "aarch64-darwin" ];
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
              jjStackOverlay
              kajjiOverlay
              jjRyuOverlay
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
