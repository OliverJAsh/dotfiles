{
  lib,
  rustPlatform,
  fetchFromGitHub,
  openssl,
  pkg-config,
}:

rustPlatform.buildRustPackage rec {
  pname = "weave";
  version = "0.2.3";

  src = fetchFromGitHub {
    owner = "Ataraxy-Labs";
    repo = "weave";
    rev = "v${version}";
    hash = "sha256-lW1xFAnpQDmJyROM/5bB4IE2N3pBlJxI/nwOGw+HOCg=";
  };

  cargoHash = "sha256-DwPKB+6ejvJa2jed12CdpTvnJeWRXfQC0q3sOixc4x0=";

  cargoBuildFlags = [ "-p" "weave-cli" ];
  cargoTestFlags = cargoBuildFlags;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = {
    description = "A semantic merge driver for Git";
    homepage = "https://github.com/Ataraxy-Labs/weave";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "weave";
    platforms = lib.platforms.unix;
  };
}
