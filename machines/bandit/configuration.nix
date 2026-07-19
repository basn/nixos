{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./services/plex.nix
    ./services/sonarr.nix
    ./services/radarr.nix
    ./services/prowlarr.nix
    ./services/attic.nix
    ./services/ci-runner.nix
    ./services/nginx.nix
    ./services/bittorrent.nix
    ./services/unpackerr.nix
    ./rclone/rclone.nix
    ./services/jellyfin.nix
    ./sops.nix
    ../../common/zfs.nix
    ./services/immich.nix
    inputs.sops_nix.nixosModules.sops
  ];
  boot = {
    kernelModules = [
      "kvm-intel"
      "r8169"
      "nct6775"
      "drivetemp"
    ];
    kernelParams = [ "ip=dhcp" ];
    supportedFilesystems = [ "zfs" ];
    initrd = {
      kernelModules = [ "r8169" ];
      availableKernelModules = [
        "r8169"
        "vmd"
        "xhci_pci"
        "mpt3sas"
        "ahci"
        "usb_storage"
        "sd_mod"
      ];
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [ "/root/hostkey.ssh" ];
          authorizedKeys =
            with lib;
            concatLists (
              mapAttrsToList (
                name: user: if elem "wheel" user.extraGroups then user.openssh.authorizedKeys.keys else [ ]
              ) config.users.users
            );
        };
      };
      systemd.services.zfs-setup-root-profile = {
        description = "Prepare root .profile for ZFS unlocking via SSH";
        wantedBy = [ "initrd.target" ];
        before = [ "initrd-root-fs.target" ];
        unitConfig.DefaultDependencies = false;
        script = ''
          mkdir -p /var/empty
          echo "systemd-tty-ask-password-agent --watch" > /var/empty/.profile
        '';
        serviceConfig.Type = "oneshot";
      };
    };
    zfs = {
      devNodes = "/dev/disk/by-id";
      forceImportRoot = false;
    };
    loader = {
      grub = {
        enable = true;
        zfsSupport = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        mirroredBoots = [
          {
            devices = [ "nodev" ];
            path = "/boot1";
          }
          {
            devices = [ "nodev" ];
            path = "/boot2";
          }
        ];
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
      neededForBoot = true;
    };
    "/data/files" = {
      device = "data/files";
      fsType = "zfs";
      encrypted.keyFile = "/root/zfs-data.key";
    };
    "/data/immich" = {
      device = "data/immich";
      fsType = "zfs";
    };
    "/data2/files" = {
      device = "data2/files";
      fsType = "zfs";
      encrypted.keyFile = "/root/zfs-data2.key";
    };
    "/data/attic" = {
      device = "data2/attic";
      fsType = "zfs";
    };
    "/boot1" = {
      device = "/dev/disk/by-uuid/7821-EDA9";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
    "/boot2" = {
      device = "/dev/disk/by-uuid/7824-6948";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };
  networking = {
    interfaces = {
      enp5s0 = {
        useDHCP = true;
      };
    };
    nameservers = [ "10.1.1.8" ];
    enableIPv6 = false;
    timeServers = [ "ntp1.sp.se" ];
    hostName = "bandit";
    hostId = "4c79e250";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
      ];
    };
  };
  environment = {
    systemPackages = with pkgs; [
      lm_sensors
      rclone
      smartmontools
    ];
  };
  systemd.services.bandit-chassis-fans = {
    description = "Control chassis fan duty from hard drive temperatures";
    after = [ "systemd-modules-load.service" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ coreutils ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "10s";
    };
    script = ''
      set -eu

      fan_hwmon=
      for dir in /sys/class/hwmon/hwmon*; do
        if [ "$(cat "$dir/name" 2>/dev/null || true)" = "nct6798" ]; then
          fan_hwmon="$dir"
          break
        fi
      done

      if [ -z "$fan_hwmon" ]; then
        echo "nct6798 hwmon device not found" >&2
        exit 1
      fi

      last_pwm=
      set_pwm() {
        pwm="$1"
        [ "$pwm" = "$last_pwm" ] && return 0

        for channel in 2 4 5; do
          [ -w "$fan_hwmon/pwm''${channel}_enable" ] || continue
          echo 1 > "$fan_hwmon/pwm''${channel}_enable"
          echo "$pwm" > "$fan_hwmon/pwm''${channel}"
        done

        last_pwm="$pwm"
        echo "set chassis fans to pwm=$pwm"
      }

      # Leave the likely CPU fan header on the motherboard's automatic curve.
      if [ -w "$fan_hwmon/pwm1_enable" ]; then
        echo 5 > "$fan_hwmon/pwm1_enable"
      fi

      while true; do
        max_temp=0

        for dir in /sys/class/hwmon/hwmon*; do
          [ "$(cat "$dir/name" 2>/dev/null || true)" = "drivetemp" ] || continue
          for temp_file in "$dir"/temp*_input; do
            [ -e "$temp_file" ] || continue
            temp="$(cat "$temp_file")"
            if [ "$temp" -gt "$max_temp" ]; then
              max_temp="$temp"
            fi
          done
        done

        if [ "$max_temp" -eq 0 ]; then
          echo "no drive temperatures found; using cooling fallback" >&2
          set_pwm 180
          sleep 60
          continue
        fi

        if [ "$max_temp" -ge 50000 ]; then
          set_pwm 255
        elif [ "$max_temp" -ge 46000 ]; then
          set_pwm 200
        elif [ "$max_temp" -ge 42000 ]; then
          set_pwm 170
        elif [ "$max_temp" -ge 38000 ]; then
          set_pwm 140
        elif [ "$max_temp" -ge 34000 ]; then
          set_pwm 115
        else
          set_pwm 90
        fi

        sleep 60
      done
    '';
  };
  services = {
    thermald = {
      enable = true;
    };
    irqbalance = {
      enable = true;
    };
    openssh = {
      enable = true;
    };
    zfs = {
      autoScrub = {
        enable = true;
      };
      trim = {
        enable = true;
      };
    };
    smartd = {
      enable = true;
      autodetect = true;
      notifications = {
        mail = {
          sender = "bandit@basn.se";
          recipient = "basn@lan2k.org";
          mailer = "${pkgs.msmtp}/bin/msmtp";
          enable = true;
        };
      };
    };
  };
  powerManagement = {
    powertop = {
      enable = true;
    };
  };
  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
        intel-ocl
        libva-vdpau-driver
        intel-compute-runtime
      ];
    };
    cpu = {
      intel = {
        updateMicrocode = true;
      };
    };
  };
  system = {
    stateVersion = "24.05";
    autoUpgrade = {
      flake = "git+https://codeberg.org/basn/nixos";
      enable = true;
    };
  };
}
