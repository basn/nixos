{ ... }:
{
  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
      };
    };
  };
}
