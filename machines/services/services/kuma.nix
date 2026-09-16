{
  unstableSmall,
  ...
}:
{
  environment.systemPackages = with unstableSmall; [ uptime-kuma ];
  services = {
    uptime-kuma = {
      enable = true;
      package = unstableSmall.uptime-kuma;
      settings = {
        PORT = "9090";
      };
    };
  };
}
