{ lib, ... }:
{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    openFirewall = true;
    host = "0.0.0.0";
    user = "ollama";
    group = "ollama";
  };

  services = {
    open-webui = {
      enable = true;
      host = "0.0.0.0";
      environment = {
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      };
    };
    udev.extraRules = ''
      KERNEL=="nvidia-cap*", MODE="0660", GROUP="video"
    '';
  };

  users.users.ollama.extraGroups = [
    "video"
    "render"
  ];

  systemd.services.ollama.serviceConfig = {
    DynamicUser = lib.mkForce false;
    SupplementaryGroups = lib.mkForce [
      "video"
      "render"
    ];
  };

  networking.firewall.interfaces.wt0.allowedTCPPorts = [ 8080 ];
}
