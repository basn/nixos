{
  unstablePkgs,
  ...
}:
{
  environment.systemPackages = with unstablePkgs; [ uptime-kuma ];
  services = {
    uptime-kuma = {
      enable = true;
      package = unstablePkgs.uptime-kuma;
      settings = {
        PORT = "9090";
      };
    };
  };
}
