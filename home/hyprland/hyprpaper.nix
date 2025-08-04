{ ... }:
{
  services = {
    hyprpaper = {
      enable = true;
      settings = {
        preload = [ "/home/basn/nixos.png" ];
        wallpaper = [ ",/home/basn/nixos.png" ];
      };
    };
  };
}
