{
  config,
  lib,
  pkgs,
  ...
}:

{
  users = {
    users.gitea-runner = {
      isSystemUser = true;
      group = "gitea-runner";
      home = "/var/lib/gitea-runner";
      createHome = true;
    };
    groups.gitea-runner = { };
  };

  nix.settings.trusted-users = [
    "@wheel"
    "gitea-runner"
  ];

  services.gitea-actions-runner.instances.codeberg = {
    enable = true;
    name = "bandit";
    url = "https://codeberg.org";
    tokenFile = config.sops.secrets.gitea-actions-runner-env.path;
    labels = [ "nix-nightly:host" ];
    hostPackages = with pkgs; [
      attic-client
      bash
      coreutils
      curl
      findutils
      gawk
      git
      gnugrep
      gnused
      gnutar
      jq
      nodejs
      nvd
      openssh
      ripgrep
      config.nix.package
    ];
    settings = {
      runner.capacity = 8;
    };
  };

  systemd.services.gitea-runner-codeberg.serviceConfig.DynamicUser = lib.mkForce false;
}
