{
  unstablePkgs,
  ...
}:
{
  environment.systemPackages = with unstablePkgs; [ uptime-kuma ];
  services = {
    uptime-kuma = {
      enable = true;
      settings = {
        PORT = "9090";
      };
    };
  };
}
