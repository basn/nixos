{ pkgs, inputs, ... }:
{
  hjem = {
    users = {
      basn = {
        packages = [
          pkgs.vivaldi
          pkgs.vivaldi-ffmpeg-codecs
          pkgs.chromium
          pkgs.google-chrome
          inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      };
    };
  };
}
