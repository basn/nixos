{ config, pkgs, ... }:
let
  monitoredHosts = [
    "bandit.netbird.basn.se"
    "battlestation.netbird.basn.se"
    "skullcanyon.netbird.basn.se"
    "vault.netbird.basn.se"
    "nixos-sov.netbird.basn.se"
    "nixos-sov2.netbird.basn.se"
  ];

  nodeTargets = [ "127.0.0.1:9100" ] ++ map (host: "${host}:9100") monitoredHosts;
  smartctlTargets = [ "127.0.0.1:9633" ] ++ map (host: "${host}:9633") monitoredHosts;

  overviewDashboard = pkgs.writeText "infrastructure-overview.json" (
    builtins.toJSON {
      id = null;
      uid = "infrastructure-overview";
      title = "Infrastructure Overview";
      tags = [
        "infrastructure"
        "prometheus"
      ];
      timezone = "browser";
      schemaVersion = 41;
      version = 1;
      refresh = "30s";
      time = {
        from = "now-6h";
        to = "now";
      };
      templating.list = [
        {
          name = "instance";
          label = "Host";
          type = "query";
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          query = "label_values(node_uname_info, instance)";
          definition = "label_values(node_uname_info, instance)";
          includeAll = true;
          multi = true;
          allValue = ".*";
          refresh = 1;
          current = {
            text = "All";
            value = "$__all";
          };
        }
      ];
      panels = [
        {
          id = 1;
          type = "stat";
          title = "Hosts online";
          gridPos = {
            x = 0;
            y = 0;
            w = 6;
            h = 4;
          };
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          targets = [
            {
              refId = "A";
              expr = "sum(up{job=\"node\"})";
            }
          ];
          options.colorMode = "background";
          fieldConfig.defaults = {
            color.mode = "thresholds";
            thresholds.steps = [
              {
                color = "red";
                value = null;
              }
              {
                color = "green";
                value = 7;
              }
            ];
          };
        }
        {
          id = 2;
          type = "stat";
          title = "Failed systemd units";
          gridPos = {
            x = 6;
            y = 0;
            w = 6;
            h = 4;
          };
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          targets = [
            {
              refId = "A";
              expr = "sum(node_systemd_unit_state{state=\"failed\",instance=~\"$instance\"})";
            }
          ];
          options.colorMode = "background";
          fieldConfig.defaults = {
            color.mode = "thresholds";
            thresholds.steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "red";
                value = 1;
              }
            ];
          };
        }
        {
          id = 3;
          type = "stat";
          title = "Filesystems above 85%";
          gridPos = {
            x = 12;
            y = 0;
            w = 6;
            h = 4;
          };
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          targets = [
            {
              refId = "A";
              expr = "count((1 - node_filesystem_avail_bytes{fstype!~\"tmpfs|overlay\",instance=~\"$instance\"} / node_filesystem_size_bytes{fstype!~\"tmpfs|overlay\",instance=~\"$instance\"}) > 0.85)";
            }
          ];
          options.colorMode = "background";
          fieldConfig.defaults = {
            color.mode = "thresholds";
            thresholds.steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "red";
                value = 1;
              }
            ];
          };
        }
        {
          id = 4;
          type = "stat";
          title = "SMART devices";
          gridPos = {
            x = 18;
            y = 0;
            w = 6;
            h = 4;
          };
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          targets = [
            {
              refId = "A";
              expr = "count(smartctl_device{instance=~\"$instance\"})";
            }
          ];
        }
        {
          id = 5;
          type = "timeseries";
          title = "CPU usage";
          gridPos = {
            x = 0;
            y = 4;
            w = 12;
            h = 8;
          };
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          targets = [
            {
              refId = "A";
              expr = "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\",instance=~\"$instance\"}[5m])) * 100)";
              legendFormat = "{{instance}}";
            }
          ];
          fieldConfig.defaults.unit = "percent";
        }
        {
          id = 6;
          type = "timeseries";
          title = "Memory usage";
          gridPos = {
            x = 12;
            y = 4;
            w = 12;
            h = 8;
          };
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          targets = [
            {
              refId = "A";
              expr = "100 * (1 - node_memory_MemAvailable_bytes{instance=~\"$instance\"} / node_memory_MemTotal_bytes{instance=~\"$instance\"})";
              legendFormat = "{{instance}}";
            }
          ];
          fieldConfig.defaults.unit = "percent";
        }
        {
          id = 7;
          type = "timeseries";
          title = "Root filesystem usage";
          gridPos = {
            x = 0;
            y = 12;
            w = 12;
            h = 8;
          };
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          targets = [
            {
              refId = "A";
              expr = "100 * (1 - node_filesystem_avail_bytes{mountpoint=\"/\",instance=~\"$instance\"} / node_filesystem_size_bytes{mountpoint=\"/\",instance=~\"$instance\"})";
              legendFormat = "{{instance}}";
            }
          ];
          fieldConfig.defaults.unit = "percent";
        }
        {
          id = 8;
          type = "timeseries";
          title = "Network traffic";
          gridPos = {
            x = 12;
            y = 12;
            w = 12;
            h = 8;
          };
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          targets = [
            {
              refId = "A";
              expr = "sum by (instance) (rate(node_network_receive_bytes_total{device!~\"lo|veth.*|podman.*\",instance=~\"$instance\"}[5m]))";
              legendFormat = "{{instance}} receive";
            }
            {
              refId = "B";
              expr = "sum by (instance) (rate(node_network_transmit_bytes_total{device!~\"lo|veth.*|podman.*\",instance=~\"$instance\"}[5m]))";
              legendFormat = "{{instance}} transmit";
            }
          ];
          fieldConfig.defaults.unit = "Bps";
        }
      ];
    }
  );

  dashboards = pkgs.linkFarm "grafana-dashboards" [
    {
      name = "infrastructure-overview.json";
      path = overviewDashboard;
    }
  ];
in
{
  services = {
    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9091;
      retentionTime = "30d";
      globalConfig.scrape_interval = "30s";
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [ { targets = nodeTargets; } ];
        }
        {
          job_name = "smartctl";
          scrape_interval = "5m";
          static_configs = [ { targets = smartctlTargets; } ];
        }
      ];
    };

    grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3000;
          domain = "grafana.basn.se";
          root_url = "https://grafana.basn.se/";
        };
        analytics = {
          reporting_enabled = false;
          check_for_updates = false;
        };
        security = {
          disable_initial_admin_creation = true;
          secret_key = "$__file{${config.sops.secrets.grafana-secret-key.path}}";
        };
        auth = {
          disable_login_form = true;
          disable_signout_menu = true;
        };
        "auth.proxy" = {
          enabled = true;
          header_name = "X-authentik-username";
          header_property = "username";
          auto_sign_up = true;
          headers = "Email:X-authentik-email Name:X-authentik-name";
        };
        users.auto_assign_org_role = "Admin";
      };
      provision = {
        enable = true;
        datasources.settings = {
          apiVersion = 1;
          prune = true;
          datasources = [
            {
              name = "Prometheus";
              uid = "prometheus";
              type = "prometheus";
              access = "proxy";
              url = "http://127.0.0.1:9091";
              isDefault = true;
              editable = false;
            }
          ];
        };
        dashboards.settings = {
          apiVersion = 1;
          providers = [
            {
              name = "Infrastructure";
              type = "file";
              disableDeletion = true;
              editable = false;
              options.path = dashboards;
            }
          ];
        };
      };
    };
  };
}
