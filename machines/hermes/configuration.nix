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
      extraPackages = [
        agentBrowser
        pkgs.chromium
        pkgs.docker
        pkgs.jq
        pkgs."mcp-nixos"
      ];
      environment = {
        AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
        AGENT_BROWSER_ENGINE = "chrome";
        HASS_URL = "https://hass.basn.se";
        HERMES_DOCKER_BINARY = "${pkgs.docker}/bin/docker";
        FIRECRAWL_API_URL = "http://127.0.0.1:3002";
        SEARXNG_URL = "https://search.basn.se";
      };
      settings = {
        _config_version = 27;
        model = {
          provider = "openai-codex";
          default = "gpt-5.5";
          openai_runtime = "auto";
        };
        auxiliary = {
          # Keep the agent loop, tool routing, and vision on GPT-5.5. These
          # narrow background tasks do not need the default model's capability.
          approval = {
            provider = "openai-codex";
            model = "gpt-5.4-mini";
          };
          compression = {
            provider = "openai-codex";
            model = "gpt-5.4-mini";
          };
          curator = {
            provider = "openai-codex";
            model = "gpt-5.4-mini";
          };
          skills_hub = {
            provider = "openai-codex";
            model = "gpt-5.4-mini";
          };
          title_generation = {
            provider = "openai-codex";
            model = "gpt-5.4-mini";
          };
          web_extract = {
            provider = "openai-codex";
            model = "gpt-5.4-mini";
          };
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
          extract_backend = "firecrawl";
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
        mcp_servers.nixos = {
          command = "${pkgs."mcp-nixos"}/bin/mcp-nixos";
          timeout = 120;
          connect_timeout = 60;
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
              scopes = "openid profile email offline_access";
            };
          };
        };
        unauthorized_dm_behavior = "ignore";
      };
    };
  };

  basn.nixosUpgradeNotify.enable = false;

  sops = {
    defaultSopsFile = ./secrets/hermes.env;
    defaultSopsFormat = "dotenv";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.hermes-env = {
      owner = "hermes";
      group = "hermes";
      mode = "0400";
      restartUnits = [ "hermes-agent.service" ];
    };
    secrets.firecrawl-env = {
      sopsFile = ./secrets/firecrawl.env;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  users.users.hermes.extraGroups = [ "docker" ];
  users.users.basn.extraGroups = [
    "docker"
    "hermes"
  ];

  systemd = {
    tmpfiles.rules = [
      "d /var/lib/hermes/output 2770 hermes hermes - -"
      "d /var/lib/firecrawl 0750 root root - -"
      "d /var/lib/firecrawl/postgres 0700 999 999 - -"
      "d /var/lib/firecrawl/redis 0750 999 999 - -"
      "d /var/lib/firecrawl/rabbitmq 0750 999 999 - -"
    ];
    services.firecrawl-network = {
      description = "Firecrawl private Docker network";
      wantedBy = [ "multi-user.target" ];
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.docker}/bin/docker network inspect firecrawl >/dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create firecrawl >/dev/null
      '';
    };
    services.docker-firecrawl-redis = {
      after = [ "firecrawl-network.service" ];
      requires = [ "firecrawl-network.service" ];
    };
    services.docker-firecrawl-rabbitmq = {
      after = [ "firecrawl-network.service" ];
      requires = [ "firecrawl-network.service" ];
    };
    services.docker-firecrawl-postgres = {
      after = [ "firecrawl-network.service" ];
      requires = [ "firecrawl-network.service" ];
    };
    services.docker-firecrawl-playwright = {
      after = [ "firecrawl-network.service" ];
      requires = [ "firecrawl-network.service" ];
    };
    services.docker-firecrawl-api = {
      after = [ "firecrawl-network.service" ];
      requires = [ "firecrawl-network.service" ];
    };
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
        # Hermes 0.16 otherwise sends its default OIDC scopes and receives no
        # refresh token, which logs dashboard users out after token expiry.
        HERMES_DASHBOARD_OIDC_SCOPES = "openid profile email offline_access";
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
      serviceConfig = {
        EnvironmentFile = config.sops.secrets.hermes-env.path;
        TimeoutStopSec = 210;
      };
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
    oci-containers = {
      backend = "docker";
      containers = {
        firecrawl-redis = {
          image = "redis:alpine";
          networks = [ "firecrawl" ];
          extraOptions = [
            "--network-alias=redis"
            "--memory=256m"
            "--memory-swap=256m"
            "--cpus=0.5"
          ];
          volumes = [ "/var/lib/firecrawl/redis:/data" ];
          cmd = [
            "redis-server"
            "--appendonly"
            "yes"
            "--bind"
            "0.0.0.0"
          ];
        };
        firecrawl-rabbitmq = {
          image = "rabbitmq:3-management";
          networks = [ "firecrawl" ];
          extraOptions = [
            "--network-alias=rabbitmq"
            "--memory=512m"
            "--memory-swap=512m"
            "--cpus=0.5"
          ];
          volumes = [ "/var/lib/firecrawl/rabbitmq:/var/lib/rabbitmq" ];
        };
        firecrawl-postgres = {
          image = "ghcr.io/firecrawl/nuq-postgres:latest";
          networks = [ "firecrawl" ];
          extraOptions = [
            "--network-alias=nuq-postgres"
            "--memory=512m"
            "--memory-swap=512m"
            "--cpus=0.5"
          ];
          environmentFiles = [ config.sops.secrets.firecrawl-env.path ];
          environment = {
            POSTGRES_USER = "postgres";
            POSTGRES_DB = "postgres";
          };
          volumes = [ "/var/lib/firecrawl/postgres:/var/lib/postgresql/data" ];
        };
        firecrawl-playwright = {
          image = "ghcr.io/firecrawl/playwright-service:latest";
          networks = [ "firecrawl" ];
          extraOptions = [
            "--network-alias=playwright-service"
            "--memory=1536m"
            "--memory-swap=1536m"
            "--cpus=1.0"
            "--cap-drop=ALL"
            "--security-opt=no-new-privileges:true"
            "--tmpfs=/tmp/.cache:noexec,nosuid,size=512m"
          ];
          environment = {
            PORT = "3000";
            MAX_CONCURRENT_PAGES = "1";
            BLOCK_MEDIA = "true";
          };
        };
        firecrawl-api = {
          image = "ghcr.io/firecrawl/firecrawl:latest";
          networks = [ "firecrawl" ];
          dependsOn = [
            "firecrawl-redis"
            "firecrawl-rabbitmq"
            "firecrawl-postgres"
            "firecrawl-playwright"
          ];
          ports = [ "127.0.0.1:3002:3002" ];
          extraOptions = [
            "--memory=4g"
            "--memory-swap=4g"
            "--cpus=1.5"
          ];
          environmentFiles = [ config.sops.secrets.firecrawl-env.path ];
          environment = {
            REDIS_URL = "redis://redis:6379";
            REDIS_RATE_LIMIT_URL = "redis://redis:6379";
            PLAYWRIGHT_MICROSERVICE_URL = "http://playwright-service:3000/scrape";
            POSTGRES_USER = "postgres";
            POSTGRES_DB = "postgres";
            POSTGRES_HOST = "nuq-postgres";
            POSTGRES_PORT = "5432";
            USE_DB_AUTHENTICATION = "false";
            NUM_WORKERS_PER_QUEUE = "1";
            CRAWL_CONCURRENT_REQUESTS = "1";
            MAX_CONCURRENT_JOBS = "1";
            BROWSER_POOL_SIZE = "1";
            HOST = "0.0.0.0";
            PORT = "3002";
            EXTRACT_WORKER_PORT = "3004";
            WORKER_PORT = "3005";
            NUQ_RABBITMQ_URL = "amqp://rabbitmq:5672";
            HARNESS_STARTUP_TIMEOUT_MS = "120000";
            ENV = "local";
          };
          cmd = [
            "node"
            "dist/src/harness.js"
            "--start-docker"
          ];
        };
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
      randomizedDelaySec = "30m";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
