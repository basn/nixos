{ ... }:
{
  wayland = {
    windowManager = {
      hyprland = {
        enable = true;
        settings = {
          "$modifier" = "SUPER";
          exec-once = [
            "waybar"
            "dunst"
          ];
          input = {
            kb_layout = "se";
            follow_mouse = 1;
            sensitivity = -0.5;
            accel_profile = "flat";
            touchpad = {
              natural_scroll = false;
            };
          };
          device = {
            name = "pulsar-pulsar-8kdx-dongle-mouse";
            sensitivity = -1;
            accel_profile = "flat";
          };
          general = {
            gaps_in = 1;
            gaps_out = 1;
            border_size = 2;
            resize_on_border = true;
            allow_tearing = false;
            layout = "dwindle";
          };
          decoration = {
            active_opacity = 1;
            inactive_opacity = 1;
            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
            };
            blur = {
              enabled = false;
            };
          };
          workspace = [
            "w[tv1], gapsout:0, gapsin:0"
            "f[1], gapsout:0, gapsin:0"
          ];
          windowrule = [
            "bordersize 0, floating:0, onworkspace:w[tv1]"
            "rounding 0, floating:0, onworkspace:w[tv1]"
            "bordersize 0, floating:0, onworkspace:f[1]"
            "rounding 0, floating:0, onworkspace:f[1]"
          ];
          windowrulev2 = [
            "float, title:^(.*Bitwarden.*)$"
            "float, title:^(.*Friends List*.)$"
            "workspace 5 silent, monitor 1, class:^(discord)$"
            "workspace 4 silent, monitor 0, class:^(spotify)$"
          ];
          animations = {
            enabled = true;
            bezier = [
              "overshot, 0.05, 0.9, 0.1, 1.05"
              "smoothOut, 0.5, 0, 0.99, 0.99"
              "smoothIn, 0.5, -0.5, 0.68, 1.5"
            ];
            animation = [
              "windows, 1, 5, overshot, slide"
              "windowsOut, 1, 3, smoothOut"
              "windowsIn, 1, 3, smoothOut"
              "windowsMove, 1, 4, smoothIn, slide"
              "border, 1, 5, default"
              "fade, 1, 5, smoothIn"
              "fadeDim, 1, 5, smoothIn"
              "workspaces, 1, 6, default"
            ];
          };
          ecosystem = {
            no_donation_nag = true;
            no_update_news = true;
          };
          dwindle = {
            pseudotile = true;
            preserve_split = true;
            smart_split = false;
            smart_resizing = false;
          };
          bind = [
            "$modifier, T, exec, ghostty"
            "$modifier, Q, killactive"
            "$modifier_shift, M, exit"
            "$modifier, E, exec, dolphin"
            "$modifier, V, togglefloating"
            "$modifier, R, exec, rofi -show combi -show-icons"
            "$modifier, SPACE, exec, rofi -show drun -show-icons" 
            "$modifier, TAB, exec , rofi -show window -show-icons"
            "$modifier, P, pseudo"
            "$modifier, J, togglesplit"
            "$modifier, L, exec, loginctl lock-session"
            # super + arrowkeys
            "$modifier, left, movefocus, l"
            "$modifier, right, movefocus, r"
            "$modifier, up, movefocus, u"
            "$modifier, down, movefocus, d"
            # workspaces
            "$modifier, 1, workspace, 1"
            "$modifier, 2, workspace, 2"
            "$modifier, 3, workspace, 3"
            "$modifier, 4, workspace, 4"
            "$modifier, 5, workspace, 5"
            "$modifier, 6, workspace, 6"
            "$modifier, 7, workspace, 7"
            "$modifier, 8, workspace, 8"
            "$modifier, 9, workspace, 9"
            "$modifier, 0, workspace, 10"
            "$modifier SHIFT, 1, movetoworkspace, 1"
            "$modifier SHIFT, 2, movetoworkspace, 2"
            "$modifier SHIFT, 3, movetoworkspace, 3"
            "$modifier SHIFT, 4, movetoworkspace, 4"
            "$modifier SHIFT, 5, movetoworkspace, 5"
            "$modifier SHIFT, 6, movetoworkspace, 6"
            "$modifier SHIFT, 7, movetoworkspace, 7"
            "$modifier SHIFT, 8, movetoworkspace, 8"
            "$modifier SHIFT, 9, movetoworkspace, 9"
            "$modifier SHIFT, 0, movetoworkspace, 10"
            ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
            ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ",XF86AudioPlay, exec, playerctl play-pause"
            ",XF86AudioPause, exec, playerctl play-pause"
            ",XF86AudioNext, exec, playerctl next"
            ",XF86AudioPrev, exec, playerctl previous"
            "$modifier, PRINT, exec, hyprshot -m window"
            ", PRINT, exec, hyprshot -m output"
            "$modifier_shift, PRINT, exec, hyprshot -m region"
          ];
          bindm = [
            "$modifier, mouse:272, movewindow"
            "$modifier, mouse:273, resizewindow"
          ];
          master = {
            new_status = "master";
          };
          monitor = [
            "desc: Samsung Electric Company Odyssey G50A HNMTC00138, prefered, auto-right, auto"
            "desc: Samsung Electric Company Odyssey G5 HNAX900314, prefered, auto-left, auto"
          ];
          env = [
            "HYPRCURSOR_THEME,volantes"
            "HYPRCURSOR_SIZE,24"
            "LIBVA_DRIVER_NAME,nvidia"
            "__GLX_VENDOR_LIBRARY_NAME,nvidia"
            "ELECTRON_OZONE_PLATFORM_HINT,auto"
            "NVD_BACKEND,direct"
          ];
        };
      };
    };
  };
}
