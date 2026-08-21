{ pkgs, ... }:
{
  fonts.packages = with pkgs; [ nerd-fonts.meslo-lg ];
  hjem = {
    users = {
      basn = {
        packages = [ pkgs.ghostty ];
        files = {
          ".config/ghostty/config".source = ./configs/ghostty.conf;
          ".local/share/applications/com.mitchellh.ghostty.desktop".source =
            ./configs/com.mitchellh.ghostty.desktop;
        };
      };
    };
  };
}
