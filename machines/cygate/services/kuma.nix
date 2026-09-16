{ unstableSmall, ... }:
{
  environment.systemPackages = with unstableSmall; [
    uptime-kuma
  ];
  services = {
    uptime-kuma = {
      enable = true;
      settings = {
        PORT = "9090";
      };
    };
  };
}
