{ config, pkgs, ... }:
let
  llamaCppCuda = pkgs.llama-cpp.override {
    cudaSupport = true;
  };
in
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = false;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  users.groups.llama-cpp = { };
  users.users.llama-cpp = {
    isSystemUser = true;
    group = "llama-cpp";
    home = "/var/lib/llama-cpp";
    createHome = true;
  };
  environment.systemPackages = [
    llamaCppCuda
    pkgs.pciutils
  ];
  systemd.services.llama-server = {
    description = "CUDA llama.cpp server for Hermes";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "nvidia-persistenced.service"
    ];
    environment = {
      HOME = "/var/lib/llama-cpp";
      CUDA_VISIBLE_DEVICES = "0";
    };
    serviceConfig = {
      User = "llama-cpp";
      Group = "llama-cpp";
      StateDirectory = "llama-cpp";
      CacheDirectory = "llama-cpp";
      ExecStart = "${llamaCppCuda}/bin/llama-server --hf-repo unsloth/Qwen3.5-9B-GGUF:Q8_0 --no-mmproj --alias qwen3.5-9b-local --host 0.0.0.0 --port 8080 --ctx-size 131072 --parallel 2 --cache-type-k q8_0 --cache-type-v q8_0 --flash-attn auto --gpu-layers all --fit off --jinja --metrics";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStartSec = "30min";
    };
  };
}
