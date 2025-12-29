{ pkgs, ... }:
{
  programs = {
    msmtp = {
      enable = true;
      setSendmail = true;
      defaults = {
        auth = true;
        aliases = "/etc/aliases";
        port = 587;
        tls = "on";
        tls_starttls = true;
      };
      accounts = {
        default = {
          host = "mail.lan2k.org";
          passwordeval = "cat /run/secrets/zfs";
          user = "zfs@basn.se";
          from = "zfs@basn.se";
        };
      };
    };
  };
  services = {
    zfs = {
      zed = {
        enableMail = true;
        settings = {
          ZED_EMAIL_ADDR = [ "basn@lan2k.org" ];
          ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
          ZED_NOTIFY_VERBOSE = true;
          ZED_NOTIFY_DATA = true;
        };
      };
    };
  };
}
