{ lib, stdenvNoCC, fetchurl }:

# OpenCode prebuilt (Bun --compile). NO usar autoPatchelfHook: altera el
# intérprete ELF y corrompe el bytecode embebido → el binario cae a
# `bun --help` / "Script not found". En NixOS corre vía programs.nix-ld
# (/lib64/ld-linux-x86-64.so.2), igual que el tarball oficial.
#
# Actualizar version + hash (SRI) desde:
#   https://github.com/anomalyco/opencode/releases
#   SHA256SUMS → opencode-linux-x64.tar.gz
stdenvNoCC.mkDerivation rec {
  pname = "opencode";
  version = "2.2.5";

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
    hash = "sha256-CfRDAsEP0DaRL1nIH9Gu9d9F3Qb2SRl/nfybvip5YU4=";
  };

  dontUnpack = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    chmod +x $out/bin/opencode
    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenCode AI coding agent (prebuilt binary from GitHub Releases)";
    homepage = "https://opencode.ai";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "opencode";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
