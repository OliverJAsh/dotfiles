{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "kajji";
  version = "0.9.0";

  src = fetchurl {
    url = "https://github.com/eliaskc/kajji/releases/download/v${version}/kajji-darwin-arm64.zip";
    sha256 = "sha256-I7N1gOVos/jWOWaq++56eaqfaYfXV5FCb1E0jCAHHx4=";
  };

  nativeBuildInputs = [ unzip ];
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tmp="$(mktemp -d)"
    unzip -q "$src" -d "$tmp"
    install -m755 "$tmp/kajji" "$out/bin/kajji"
    runHook postInstall
  '';

  meta = {
    description = "A simple jj TUI for local code review and day-to-day jj usage";
    homepage = "https://github.com/eliaskc/kajji";
    license = lib.licenses.mit;
    mainProgram = "kajji";
    platforms = [ "aarch64-darwin" ];
  };
}
