{ pkgs, ... }:
{
  hjem = {
    users = {
      basn = {
        packages = [
          pkgs.vivaldi
          pkgs.vivaldi-ffmpeg-codecs
          pkgs.chromium
          pkgs.google-chrome
        ];
      };
    };
  };
}
