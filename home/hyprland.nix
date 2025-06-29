{  pkgs, ... }:
{
  wayland = {
    windowManager = {
      hyprland = {
        enable = true;
        settings = {
          exec-once = [
            "nm-applet --indicator"
            "waybar"
            "hyprpaper"
            "dunst"
            "hypridle"
          ];
          input = {
            kb_layout = "se";
            follow_mouse = 1;
            sensitivity = 0;
            touchpad = {
              natural_scroll = false;
            };
          };
          device = {
            name = "pulsar-pulsar-8kdx-dongle";
            sensitivity = -0.2;
            accel_profile = "flat";
          };
          general = {
            "$modifier" = "SUPER";
            gaps_in = 1;
            gaps_out = 5;
            border_size = 2;
            col.active_border = "rgba(33ccffee) rgba(00ff99ee) 45deg";
            col.inactive_border = "rgba(595959aa)";
            resize_on_border = false;
            allow_tearing = false;
            layout = "dwindle";
          };
          decoration = {
            rouding = 10;
            rouding_power = 2;
            active_opacity = 1;
            inactive_opacity = 1;
            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              color = "rgba(1a1a1aee)";
            };
            blur = {
              enabled = false;
            };
          };
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
            no_update_news = false;
          };
          dwindle = {
            pseudotile = true;
            preserve_split = true;
            no_gaps_when_only = 1;
            smart_split = false;
            smart_resizing = false;
          };
          bind = [
            "$modifier, T, exec, $terminal"
            "$modifier, Q, killactive"
            "$modifier_shift, M, exit"
            "$modifier, E, exec, $fileManager"
            "$modifier, V, togglefloating"
            "$modifier, R, exec, $menu"
            "$modifier, P, pseudo"
            "$modifier, J, togglesplit"
            "$modifier, L, exec, hyprlock"
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
            "ALT,Tab,cyclenext"
            "ALT,Tab,bringactivetotop"
            ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
            ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            " ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ",XF86AudioPlay, exec, playerctl play-pause"
            ",XF86AudioPause, exec, playerctl play-pause"
            ",XF86AudioNext, exec, playerctl next"
            ",XF86AudioPrev, exec, playerctl previous"
          ];
          bindm = [
            "$modifier, mouse:272, movewindow"
            "$modifier, mouse:273, resizewindow"
          ];
        };
        master = {
          new_status = "master";
        };
        monitor = [
          "desc: Samsung Electric Company Odyssey G50A HNMTC00138, prefered, auto-right, 1"
          "desc: Samsung Electric Company Odyssey G5 HNAX900314, prefered, auto-left, 1"
        ];
      };
    };
  };
  programs = {
    waybar = {
      enable = true;
      package = pkgs.waybar;
      settings = [
        {
          "height" = 20; 
          "spacing" = 4;
          "modules-left" = [
            "hyprland/workspaces"
            "custom/media"
          ];
          "modules-center" = [
            "hyprland/window"
          ];
          "modules-right" = [
            "mpd"
            "idle_inhibitor"
            "pulseaudio"
            "power-profiles-daemon"
            "cpu"
            "memory"
            "temperature"
            "backlight"
            "clock"
            "tray"
            "custom/power"
          ];
          "hyprland/workspaces" = {
             "disable-scroll" = true;
             "all-outputs" = true;
             "warp-on-scroll" = false;
             "format" = "{name}: {icon}";
             "format-icons" = {
               "1" = "";
               "2" = "";
               "3" = "";
               "4" = "";
               "5" = "";
               "6" = "";
               "urgent" = "";
               "focused" = "";
               "default" = "";
             };
          };
          "keyboard-state" = {
            "numlock" = true;
            "capslock" = true;
            "format" = "{name} {icon}";
            "format-icons" = {
              "locked" = "";
              "unlocked" = "";
            };
          };
          "idle_inhibitor" = {
            "format" = "{icon}";
            "format-icons" = {
              "activated" = "";
              "deactivated" = "";
            };
          };
          "tray" = {
            "spacing" = 10;
          };
          "clock" = {
            "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            "format-alt" = "{:%Y-%m-%d}";
          };
          "cpu" = {
            "format" = "{usage}% ";
            "tooltip" = false;
          };
          "memory" = {
            "format" = "{}% ";
          };
          "temperature" = {
            "critical-threshold" = 80;
            "format" = "{temperatureC}°C {icon}";
            "format-icons" = ["" "" ""];
          };
          "backlight" = {
            "format" = "{percent}% {icon}";
            "format-icons" = ["" "" "" "" "" "" "" "" ""];
          };
          "battery" = {
            "states" = {
              "good" = 60;
              "warning" = 30;
              "critical" = 15;
            };
          "format" = "{capacity}% {icon}";
          "format-full" = "{capacity}% {icon}";
          "format-charging" = "{capacity}% ";
          "format-plugged" = "{capacity}% ";
          "format-alt" = "{time} {icon}";
          "format-icons" = ["" "" "" "" ""];
          };
          "battery#bat2" = {
            "bat" = "BAT2";
          };
          "power-profiles-daemon" = {
            "format" = "{icon}";
            "tooltip-format" = "Power profile: {profile}\nDriver: {driver}";
            "tooltip" = true;
            "format-icons" = {
              "default" = "";
              "performance" = "";
              "balanced" = "";
              "power-saver" = "";
            };
          };
          "pulseaudio" = {
            "format" = "{volume}% {icon} {format_source}";
            "format-bluetooth" = "{volume}% {icon} {format_source}";
            "format-bluetooth-muted" = " {icon} {format_source}";
            "format-muted" = " {format_source}";
            "format-source" = "{volume}% ";
            "format-source-muted" = "";
            "format-icons" = {
              "headphone" = "";
              "hands-free" = "";
              "headset" = "";
              "phone" = "";
              "portable" = "";
              "car" = "";
              "default" = ["" "" ""];
            };
            "on-click" = "pavucontrol";
          };
          "custom/media" = {
            "format" = "{icon} {text}";
            "return-type" = "json";
            "max-length" = 40;
            "format-icons" = {
              "spotify" = "";
              "default" = "🎜";
            };
            "escape" = true;
          };
        }
      ];
    };
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      extraConfig = {
        modes = [ "combi" ];
        combi-modes = [ "window" "drun" "run" ];
      };
    };
  };
  services = {
    hypridle = {
      enable = true;
      settings = {
        general = {
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "hyprlock";
          };
        listener = [
          {
            timeout = 250;
            on-timeout = "hyprlock";
          }
          {
            timeout = 500;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
  };
}
