{ pkgs, ... }:
{
  programs = {
    msmtp = {
      enable = true;
      setSendmail = true;
      defaults = {
        aliases = "/etc/aliases";
        port = 587;
        tls = "on";
      };
      accounts = {
        default = {
          host = "mail.lan2k.org";
          passwordeval = "cat /run/secrets/zfs";
          user = "basn@lan2k.org";
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
