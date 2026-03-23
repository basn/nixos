{ ... }:
{
  services.freshrss = {
    enable = true;
    baseUrl = "https://freshrss.basn.se";
    virtualHost = "freshrss.basn.se";
    authType = "none";
    passwordFile = "/run/secrets/freshrss-password";
  };
}
