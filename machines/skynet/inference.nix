{ config, pkgs, ... }:
let
  model = "Qwen/Qwen3.8-Flash-Next-FP8";
  revision = "7fb48d708ca6cd8eeed8f4db0433be18af96984f";
  checkpoint = "/var/lib/skynet-qwen38-fp8/${revision}";
in
{
  sops.secrets = {
    inference-api-key = {
      sopsFile = ./secrets/inference.yaml;
      key = "VLLM_API_KEY";
      mode = "0400";
    };
  };
  sops.templates.inference-env = {
    mode = "0400";
    content = ''
      VLLM_API_KEY=${config.sops.placeholder.inference-api-key}
    '';
    restartUnits = [ "podman-skynet-inference.service" ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "basn@lan2k.org";
  };
  networking.firewall.interfaces.ens33.allowedTCPPorts = [
    80
    443
  ];
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    virtualHosts."skynet.basn.se" = {
      default = true;
      forceSSL = true;
      enableACME = true;
      listenAddresses = [ "10.136.48.5" ];
      extraConfig = ''
        allow 193.183.116.216/32;
        allow 193.108.5.135/32;
        deny all;
      '';
      locations = {
        "/".return = "404";
        "= /v1/models" = {
          proxyPass = "http://unix:/run/skynet-inference/api/vllm.sock:/v1/models";
          extraConfig = ''
            if ($request_method != GET) { return 405; }
          '';
        };
        "= /v1/chat/completions" = {
          proxyPass = "http://unix:/run/skynet-inference/api/vllm.sock:/v1/chat/completions";
          extraConfig = ''
            if ($request_method != POST) { return 405; }
            proxy_buffering off;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
          '';
        };
      };
    };
  };

  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.oci-containers = {
    backend = "podman";
    containers.skynet-inference = {
      image = "docker.io/vllm/vllm-openai:v0.34.0@sha256:20fdb089454afbb324efa4110a2c025ff7b27cc1a086e07aa580b18df8ad1ce1";
      networks = [ "none" ];
      environment = {
        HF_HOME = "/tmp/hf";
        HF_HUB_OFFLINE = "1";
        TRANSFORMERS_OFFLINE = "1";
        HF_HUB_DISABLE_TELEMETRY = "1";
        VLLM_NO_USAGE_STATS = "1";
        VLLM_USE_RUST_FRONTEND = "0";
        VLLM_HOST_IP = "127.0.0.1";
        NCCL_SOCKET_IFNAME = "=lo";
        GLOO_SOCKET_IFNAME = "lo";
      };
      environmentFiles = [ config.sops.templates.inference-env.path ];
      volumes = [
        "${checkpoint}/checkpoint:/model:ro"
        "/run/skynet-inference/api:/run/inference"
      ];
      devices = [ "nvidia.com/gpu=all" ];
      extraOptions = [
        "--ipc=private"
        "--shm-size=16g"
        "--ulimit=memlock=-1:-1"
        "--memory=320g"
        "--memory-swap=320g"
        "--umask=0007"
      ];
      cmd = [
        "/model"
        "--served-model-name=${model}"
        "--load-format=safetensors"
        "--uds=/run/inference/vllm.sock"
        "--tensor-parallel-size=2"
        "--distributed-executor-backend=mp"
        "--max-model-len=262144"
        "--max-num-seqs=4"
        ''--engram-config={"cpu_offload":true,"disk_offload":false,"dp_shared_memory":false}''
        "--moe-backend=triton"
        "--kv-cache-dtype=fp8"
        "--attention-config.indexer_kv_dtype=fp8"
        "--gpu-memory-utilization=0.88"
        "--disable-prefix-caching"
        "--language-model-only"
        "--reasoning-parser=qwen3"
        "--enable-auto-tool-choice"
        "--tool-call-parser=qwen3_coder"
      ];
    };
  };

  systemd.services.podman-skynet-inference = {
    preStart = ''
      key=${config.sops.secrets.inference-api-key.path}
      test -r "$key" && test "$(${pkgs.coreutils}/bin/wc -c < "$key")" -eq 64 &&
        ${pkgs.gnugrep}/bin/grep -qxE '[0-9a-f]{64}' "$key" || exit 1
      test -s ${checkpoint}/checkpoint/model.safetensors.index.json &&
        ${pkgs.gnugrep}/bin/grep -Fq '"revision": "${revision}"' ${checkpoint}/verified.json || exit 1
      ${pkgs.coreutils}/bin/install -d -m 2750 -o root -g ${config.services.nginx.group} /run/skynet-inference/api
    '';
    # Daemonless Podman does not inherit the toolkit's podman.service ordering.
    requires = [ "nvidia-container-toolkit-cdi-generator.service" ];
    after = [ "nvidia-container-toolkit-cdi-generator.service" ];
    serviceConfig = {
      StateDirectory = "skynet-inference";
      StateDirectoryMode = "0700";
      # nginx traverses only the parent; Podman's own runtime files stay private.
      RuntimeDirectoryMode = "0755";
      UMask = "0077";
      RestartSec = "30s";
    };
  };
}
