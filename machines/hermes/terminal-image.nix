{ pkgs }:
let
  audit = pkgs.writeShellApplication {
    name = "basn-audit";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      git
      skopeo
      openssh
      python3
      getent
    ];
    text = builtins.readFile ./basn-audit.sh;
  };
  sshConfig = pkgs.runCommand "hermes-audit-ssh-config" { } ''
    mkdir -p $out/etc/ssh
    cp ${./audit-ssh-config} $out/etc/ssh/audit_config
    cp ${./audit-known-hosts} $out/etc/ssh/audit_known_hosts
  '';
  root = pkgs.buildEnv {
    name = "hermes-terminal-root";
    paths = with pkgs; [
      bashInteractive
      coreutils
      curl
      git
      gh
      skopeo
      openssh
      jq
      ripgrep
      python3
      nodejs
      cacert
      iproute2
      dnsutils
      findutils
      gnugrep
      gnused
      gawk
      gnutar
      gzip
      which
      dockerTools.fakeNss
      getent
      sshConfig
      audit
    ];
    pathsToLink = [
      "/bin"
      "/etc"
      "/share"
    ];
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "hermes-audit-terminal";
  contents = [ root ];
  extraCommands = ''
    mkdir -p tmp workspace root usr etc/ssh run/hermes-audit
    chmod 1777 tmp
    ln -s /bin usr/bin
  '';
  config = {
    Cmd = [ "/bin/bash" ];
    WorkingDir = "/workspace";
    Env = [
      "PATH=/bin:/usr/bin"
      "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=/etc/ssl/certs/ca-bundle.crt"
    ];
  };
}
