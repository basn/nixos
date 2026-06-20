{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  agentBrowser = import ./agent-browser.nix { inherit pkgs; };
  hermesPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "sd_mod"
      "sr_mod"
      "virtio_blk"
      "virtio_pci"
      "virtio_scsi"
      "xhci_pci"
    ];
    kernelModules = [ ];
    supportedFilesystems = [ "zfs" ];
    zfs = {
      extraPools = [ "osdisk" ];
      devNodes = "/dev/disk/by-partlabel";
      forceImportRoot = false;
    };
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = false;
        efiSysMountPoint = "/boot";
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "osdisk/root";
      fsType = "zfs";
    };
    "/nix" = {
      device = "osdisk/nix";
      fsType = "zfs";
    };
    "/var" = {
      device = "osdisk/var";
      fsType = "zfs";
    };
    "/home" = {
      device = "osdisk/home";
      fsType = "zfs";
    };
    "/var/lib/hermes" = {
      device = "osdisk/hermes";
      fsType = "zfs";
    };
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  networking = {
    hostName = "hermes";
    hostId = "441e7335";
    enableIPv6 = false;
    useDHCP = false;
    defaultGateway = "10.1.1.1";
    nameservers = [ "10.1.1.8" ];
    interfaces.enp1s0.ipv4.addresses = [
      {
        address = "10.1.1.10";
        prefixLength = 24;
      }
    ];
    nftables = {
      enable = true;
      tables.hermes-egress = {
        family = "inet";
        content = ''
          chain output {
            type filter hook output priority 10; policy accept;

            ct state established,related accept
            ip daddr 10.1.1.8 udp dport 53 accept
            ip daddr 10.1.1.8 tcp dport { 53, 443 } accept
            ip daddr 10.0.0.0/8 reject
            ip daddr 172.16.0.0/12 reject
            ip daddr 192.168.0.0/16 reject
            ip daddr 100.64.0.0/10 reject
            ip daddr 169.254.0.0/16 reject
          }

          chain forward {
            type filter hook forward priority 10; policy accept;

            iifname "docker0" ip daddr 10.1.1.8 udp dport 53 accept
            iifname "docker0" ip daddr 10.1.1.8 tcp dport { 53, 443 } accept

            iifname "docker0" ip daddr 10.0.0.0/8 reject
            iifname "docker0" ip daddr 172.16.0.0/12 reject
            iifname "docker0" ip daddr 192.168.0.0/16 reject
            iifname "docker0" ip daddr 100.64.0.0/10 reject
            iifname "docker0" ip daddr 169.254.0.0/16 reject
          }
        '';
      };
    };
    firewall = {
      enable = true;
      extraInputRules = ''
        ip saddr 10.0.0.0/8 tcp dport 22 accept
        ip saddr 172.16.0.0/12 tcp dport 22 accept
        ip saddr 192.168.0.0/16 tcp dport 22 accept
        ip saddr 10.1.1.8 tcp dport 9119 accept
      '';
    };
  };

  services = {
    netbird.enable = lib.mkForce false;
    openssh.enable = true;
    qemuGuest.enable = true;
    zfs = {
      autoScrub.enable = true;
      trim = {
        enable = true;
        interval = "weekly";
      };
    };
    sanoid = {
      enable = true;
      templates.hermes = {
        hourly = 24;
        daily = 14;
        monthly = 3;
        autoprune = true;
        autosnap = true;
      };
      datasets."osdisk/hermes".useTemplate = [ "hermes" ];
    };
    hermes-agent = {
      enable = true;
      package = hermesPackage;
      addToSystemPackages = true;
      stateDir = "/var/lib/hermes";
      workingDirectory = "/var/lib/hermes/workspace";
      environmentFiles = [ "/var/lib/hermes/secrets.env" ];
      extraPackages = [
        agentBrowser
        pkgs.chromium
        pkgs.docker
        pkgs.jq
      ];
      environment = {
        AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
        AGENT_BROWSER_ENGINE = "chrome";
        HASS_URL = "https://hass.basn.se";
        HERMES_DOCKER_BINARY = "${pkgs.docker}/bin/docker";
        SEARXNG_URL = "https://search.basn.se";
      };
      settings = {
        _config_version = 27;
        model = {
          provider = "openai-codex";
          default = "gpt-5.4";
          openai_runtime = "auto";
        };
        timezone = "Europe/Stockholm";
        terminal = {
          backend = "docker";
          cwd = "/workspace";
          timeout = 180;
          docker_image = "nikolaik/python-nodejs:python3.11-nodejs20";
          docker_forward_env = [ ];
          docker_volumes = [
            "/var/lib/hermes/output:/output"
          ];
          container_cpu = 2;
          container_memory = 6144;
          container_disk = 61440;
          container_persistent = true;
          docker_persist_across_processes = true;
          docker_orphan_reaper = true;
        };
        code_execution = {
          mode = "strict";
          timeout = 300;
          max_tool_calls = 50;
        };
        toolsets = [
          "terminal"
          "file"
          "web"
          "browser"
          "skills"
          "memory"
          "session_search"
          "clarify"
          "code_execution"
          "delegation"
          "cronjob"
          "todo"
          "homeassistant"
        ];
        web = {
          backend = "searxng";
          search_backend = "searxng";
        };
        browser = {
          engine = "chrome";
          inactivity_timeout = 120;
          command_timeout = 30;
          record_sessions = false;
          auto_local_for_private_urls = false;
        };
        approvals = {
          mode = "manual";
          timeout = 120;
          cron_mode = "deny";
          mcp_reload_confirm = true;
          destructive_slash_confirm = true;
        };
        security = {
          redact_secrets = true;
          allow_private_urls = false;
          allow_lazy_installs = false;
          tirith_enabled = true;
          tirith_fail_open = false;
        };
        checkpoints = {
          enabled = true;
          max_snapshots = 20;
        };
        compression = {
          enabled = true;
          threshold = 0.85;
        };
        delegation = {
          max_concurrent_children = 2;
          max_spawn_depth = 1;
          orchestrator_enabled = true;
        };
        platforms.homeassistant = {
          enabled = false;
          extra = {
            watch_all = false;
            watch_domains = [
            ];
            cooldown_seconds = 30;
          };
        };
        dashboard = {
          public_url = "https://hermes.basn.se";
          oauth = {
            provider = "self-hosted";
            self_hosted = {
              issuer = "https://auth.basn.se/application/o/hermes/";
              client_id = "hermes-dashboard";
              scopes = "openid profile email";
            };
          };
        };
        unauthorized_dm_behavior = "ignore";
      };
    };
  };

  basn.nixosUpgradeNotify.enable = false;

  users.users.hermes.extraGroups = [ "docker" ];
  users.users.basn.extraGroups = [
    "docker"
    "hermes"
  ];

  systemd = {
    tmpfiles.rules = [
      "d /var/lib/hermes/output 2770 hermes hermes - -"
    ];
    services.hermes-dashboard = {
      description = "Hermes Agent Dashboard";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "hermes-agent.service"
      ];
      wants = [ "network-online.target" ];
      environment = {
        HOME = "/var/lib/hermes";
        HERMES_HOME = "/var/lib/hermes/.hermes";
        HERMES_MANAGED = "true";
      };
      path = [
        hermesPackage
        agentBrowser
        pkgs.chromium
        pkgs.coreutils
      ];
      serviceConfig = {
        User = "hermes";
        Group = "hermes";
        WorkingDirectory = "/var/lib/hermes/workspace";
        ExecStart = "${hermesPackage}/bin/hermes dashboard --host 0.0.0.0 --port 9119 --no-open";
        Restart = "always";
        RestartSec = 5;
        UMask = "0007";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ReadWritePaths = [ "/var/lib/hermes" ];
      };
    };
    services.hermes-agent = {
      environment = lib.mkForce {
        HOME = "/var/lib/hermes";
        HERMES_HOME = "/var/lib/hermes/.hermes";
        HERMES_MANAGED = "true";
      };
      serviceConfig.TimeoutStopSec = 210;
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
    vmVariant.virtualisation = {
      memorySize = 12 * 1024;
      cores = 4;
      diskSize = 120 * 1024;
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  system = {
    stateVersion = "26.05";
    autoUpgrade = {
      enable = true;
      flake = "github:basn/nixos";
      randomizedDelaySec = "30m";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
