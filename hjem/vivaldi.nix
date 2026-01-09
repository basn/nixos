{ config, pkgs, ... }:

{
  hjem = {
    users = {
      basn = {
        packages = [ pkgs.vivaldi ];
        files.".local/share/applications/vivaldi.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Vivaldi
          GenericName=Web Browser
          Exec=vivaldi --ozone-platform=wayland --enable-features=UseOzonePlatform --use-cmd-decoder=validating --use-gl=desktop %U
          Terminal=false
          Icon=vivaldi
          Categories=Network;WebBrowser;
          MimeType=text/html;text/xml;
          StartupNotify=true
        '';
      };
    };
  };
}
