{config, lib, pkgs, ...}:
{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
      defaultNetwork = {
        settings = {
          dns_enabled = true;
	};
      };
    };
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      redbot = {
        image = "phasecorex/red-discordbot";
	extraOptions = [ "--pull=newer" ];
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/docker/redbot/:/data"
        ];
      };
      unifi = { 
        image = "jacobalberty/unifi:latest";
	extraOptions = [ "--pull=newer" ];
        ports = [ 
          "9080:8080"
          "9443:8443"
          "3478:3478/udp"
          "10001:10001/udp"
        ];
        volumes = [
          "/docker/unifi:/unifi"
        ];
        environment = {
          TZ = "Europe/Stockholm";
          RUNAS_UID0 = "true";
        };
      };
      vaultwarden = {
        image = "vaultwarden/server:latest";
        ports = [ "8686:80" ];
	extraOptions = [ "--pull=newer" ];
        environment = {
          ADMIN_TOKEN = "${config.sops.secrets."vaultwarden/admintoken".path}";
          DATABASE_URL = "mysql://${config.sops.secrets."vaultwarden/dbuser".path}:${config.sops.secrets."vaultwarden/dbpass".path}@10.1.1.8/vaultwarden";
        };
        volumes = [
          "/docker/vaultwarden/:/data/"
        ];
      };
      teslamate = {
        image = "teslamate/teslamate:latest";
	ports = [ "4000:4000" ];
	extraOptions = [ "--pull=newer" ];
        environment = {
	  ENCRYPTION_KEY = "${config.sops.secrets."teslamate/enckey".path}";
          DATABASE_USER = "${config.sops.secrets."teslamate/dbuser".path}";
          DATABASE_PASS = "${config.sops.secrets."teslamate/dbpass".path}";
          DATABASE_NAME = "teslamate";
          DATABASE_HOST = "postgres";
          MQTT_HOST = "192.168.195.35";
          MQTT_USERNAME = "${config.sops.secrets."teslamate/mqttuser".path}";
          MQTT_PASSWORD = "${config.sops.secrets."teslamate/mqttpass".path}";
	};
	volumes = [
	  "/docker/teslamate/import:/opt/app/import"
	];
      };
      postgres = {
        image = "postgres:16";
	environment = {
          POSTGRES_USER = "${config.sops.secrets."teslamate/dbuser".path}";
          POSTGRES_PASSWORD = "${config.sops.secrets."teslamate/dbpass".path}";
          POSTGRES_DB = "teslamate";
        };
	volumes = [
	  "/docker/teslamate/postgres:/var/lib/postgresql/data"
	];
      };
      grafana = {
        image = "teslamate/grafana:latest";
	extraOptions = [ "--pull=newer" ];
	ports = [ "3001:3000" ];
	environment = {
          DATABASE_USER = "${config.sops.secrets."teslamate/dbuser".path}";
          DATABASE_PASS = "${config.sops.secrets."teslamate/dbpass".path}";
          DATABASE_NAME = "teslamate";
          DATABASE_HOST = "postgres";
	};
	volumes = [
	  "/docker/teslamate/grafana:/var/lib/grafana"
	];
      };
    };
  };
}
