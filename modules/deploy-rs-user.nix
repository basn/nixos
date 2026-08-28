{ lib, pkgs, ... }:
{
  users.users.deploy = {
    isNormalUser = true;
    createHome = true;
    home = "/home/deploy";
    shell = pkgs.bash;
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFfmuGPPdH0tKk0WVTIqQNmkopbmh5rUgF9EgKPNCN1N deploy-rs@nixos-sov"
    ];
  };

  # deploy-rs uses nix-store --serve over SSH when fastConnection is false.
  # That write protocol requires a trusted Nix daemon client.
  nix.settings.trusted-users = lib.mkAfter [ "deploy" ];

  # The activation wrapper is a per-generation /nix/store path.  It needs to
  # run as root to replace the root-owned system profile and activate it.
  # Magic rollback confirms a successful activation by removing its root-owned
  # canary.  Restrict that permission to deploy-rs' single Nix-hash argument.
  security.sudo.extraRules = [
    {
      users = [ "deploy" ];
      commands = [
        {
          command = "/nix/store/*/activate-rs";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/rm ^/tmp/deploy-rs-canary-[0-9a-df-np-sv-z]{32}$";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
