{ config, ... }:
{
  
  programs = {
    hyprlock = {
      enable = true;
      settings = {
      general = {
          disable_loading_bar = true;
          immediate_render = true;
          hide_cursor = false;
          no_fade_in = true;
        };

      animation = [
        "inputFieldDots, 1, 2, linear"
        "fadeIn, 0"
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          font_size = 150;

          position = "0%, 30%";

          valign = "center";
          halign = "center";

          shadow_size = 20;
          shadow_passes = 2;
          shadow_boost = 0.3;
        }
        {
          monitor = "";
          text = "cmd[update:3600000] date +'%a %b %d'";
          font_size = 20;

          position = "0%, 40%";

          valign = "center";
          halign = "center";

          shadow_size = 20;
          shadow_passes = 2;
          shadow_boost = 0.3;
        }
      ];
    };
  };
  };
}
