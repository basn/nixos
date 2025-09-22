{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      rsync
    ];
  };
  users.users.backup = {
    isNormalUser = true;
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIwMs+6QCPJafLNgEjKm1Klq5xPZ8kOHaMdOCyqu7Ddr"
    ];
  };
}
