{ ... }:
{
  services.freshrss = {
    enable = true;
    baseUrl = "https://freshrss.basn.se";
    virtualHost = "freshrss.basn.se";
    passwordFile = "/run/secrets/freshrss-password";
  };
}
