{
  config,
  lib,
  pkgs,
  useManCacheEnable,
  ...
}:
let
  remoteSyslogModule = ../modules/remote-syslog-client.nix;
  remoteSyslogModuleExists = builtins.pathExists remoteSyslogModule;
in
{
  imports = [
    ./users.nix
    ./neovim.nix
    ./fish.nix
    ./openssh.nix
    ./netbird.nix
  ]
  ++ lib.optional remoteSyslogModuleExists remoteSyslogModule;
  time = {
    timeZone = "Europe/Stockholm";
  };
  networking = {
    timeServers = [
      "sth1.ntp.se"
      "sth2.ntp.se"
      "gbg1.ntp.se"
      "gbg2.ntp.se"
    ];
  };
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "sv_SE.UTF-8";
      LC_MONETARY = "sv_SE.UTF-8";
      LC_MEASUREMENT = "sv_SE.UTF-8";
    };
  };
  console = {
    font = "Lat2-Terminus16";
    keyMap = "sv-latin1";
  };
  users = {
    defaultUserShell = pkgs.fish;
  };
  security = {
    sudo = {
      wheelNeedsPassword = false;
    };
  };
  environment = {
    systemPackages = with pkgs; [
      neovim
      wget
      btop
      dysk
      unzip
      screen
      nmap
      sops
      git
      ipcalc
      nh
      dust
      fish
      nixfmt
      trippy
      ripgrep
    ];
  };
  programs = {
    mtr = {
      enable = true;
    };
    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 4d --keep 3";
      };
      flake = "/home/basn/nixos";
    };
  };
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "@wheel" ];
    };
    sshServe = {
      trusted = true;
    };
  };
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
}
# Only set remote syslog defaults when the module is available in this source tree.
# This avoids flake eval failures while the module is not yet deployed everywhere.
// lib.optionalAttrs remoteSyslogModuleExists {
  basn.remoteSyslog = {
    enable = lib.mkDefault (config.networking.hostName != "logger");
    target = lib.mkDefault "logger";
    port = lib.mkDefault 1514;
    protocol = lib.mkDefault "tcp";
  };
}
// lib.optionalAttrs (!useManCacheEnable) {
  documentation.man.generateCaches = false;
}
// lib.optionalAttrs useManCacheEnable {
  documentation.man.cache.enable = false;
}
