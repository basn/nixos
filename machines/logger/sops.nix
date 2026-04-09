{
  config,
  ...
}:
{
  sops = {
    defaultSopsFile = ./secrets/logger.yaml;
    age.keyFile = "/home/basn/.config/sops/age/keys.txt";

    secrets = {
      graylog-password-secret = {
        key = "graylog_password_secret";
        restartUnits = [ "graylog.service" ];
      };
      graylog-root-password-sha2 = {
        key = "graylog_root_password_sha2";
        restartUnits = [ "graylog.service" ];
      };
    };

    templates."graylog-env" = {
      owner = config.services.graylog.user;
      content = ''
        GRAYLOG_PASSWORD_SECRET=${config.sops.placeholder."graylog-password-secret"}
        GRAYLOG_ROOT_PASSWORD_SHA2=${config.sops.placeholder."graylog-root-password-sha2"}
      '';
    };
  };
}
