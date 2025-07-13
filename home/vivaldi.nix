{ ... }:
{
 xdg.desktopEntries = {
   vivaldi = {
      name = "Vivaldi";
      genericName = "Web Browser";
      exec = "vivaldi --ozone-platform=wayland --enable-features=UseOzonePlatform --use-cmd-decoder=validating --use-gl=desktop %U";
      terminal = false;
      categories = [ "Network" "WebBrowser" ];
      mimeType = [ "text/html" "text/xml" ];
    };
  };
}
