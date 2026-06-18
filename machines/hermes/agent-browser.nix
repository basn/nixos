{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "agent-browser";
  version = "0.26.0";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/agent-browser/-/agent-browser-0.26.0.tgz";
    hash = "sha256-ikjPQRDX3CwSwcTW0l4Lq9+jFgS1N/Bd8NyDX+L4VL8=";
  };
  sourceRoot = "package";
  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/agent-browser-linux-x64 "$out/bin/agent-browser"

    runHook postInstall
  '';
}
