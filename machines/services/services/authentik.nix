{ ... }:
{
  services.authentik = {
    enable = true;
    environmentFile = "/run/secrets/authentik";
    settings = {
      email = {
        host = "virtmx.lan2k.org";
        port = 587;
        username = "authentik@basn.se";
        use_tls = true;
        use_ssl = false;
        from = "authentik@basn.se";
      };
      disable_startup_analytics = true;
      avatars = "initials";
      postgresql.host = "/run/postgresql";
      nginx = {
        enable = true;
        enableACME = true;
        host = "auth.basn.se";
      };
    };
  };

}
