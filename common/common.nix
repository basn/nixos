{
  pkgs,
  self,
  ...
}:
{
  imports = [
    ./users.nix
    ./neovim.nix
    ./fish.nix
    ./openssh.nix
    ./netbird.nix
    ./monitoring-exporters.nix
    ../modules/nixos-upgrade-notify.nix
  ];
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
    channel = {
      enable = false;
    };
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
  documentation.man.cache.enable = false;
  # make a symlink of flake within the generation (e.g. /run/current-system/src) thanks iynaix (i am stealing this with pride)
  system.systemBuilderCommands = "ln -s ${self.sourceInfo.outPath} $out/src";
}
