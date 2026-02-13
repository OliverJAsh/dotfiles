{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "jj-ryu";
  version = "0.0.1-alpha.11";

  src = fetchFromGitHub {
    owner = "dmmulroy";
    repo = "jj-ryu";
    rev = "v${version}";
    hash = "sha256-gE4lvqyC2LRAWNDUGePklORWjyEofs/dHLHVBAub424=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };
  cargoHash = lib.fakeHash;

  # tests require `jj` in PATH; nix build sandbox doesn't have it
  doCheck = false;

  meta = {
    description = "Stacked PRs for Jujutsu (push bookmark stacks to GitHub/GitLab as chained PRs)";
    homepage = "https://github.com/dmmulroy/jj-ryu";
    license = lib.licenses.mit;
    mainProgram = "ryu";
    platforms = [ "aarch64-darwin" ];
  };
}
