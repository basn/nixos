{  pkgs, ... }:
{
  wayland = {
    windowManager = {
      hyprland = {
        enable = true;
        settings = {
          "$modifier" = "SUPER";
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
            gaps_in = 1;
            gaps_out = 5;
            border_size = 2;
            resize_on_border = false;
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
          ];
        };
      };
    };
  };
  programs = {
    waybar = {
      enable = true;
      package = pkgs.waybar;
      settings = [
        {
          "height" = 30; 
          "spacing" = 6;
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
      style = ''
        * {
           border: none;
           border-radius: 0;
           font-family: Roboto, Helvetica, Arial, sans-serif;
           font-size: 13px;
           min-height: 0;
        }
        window#waybar {
          background: rgba(43, 48, 59, 0.5);
          border-bottom: 3px solid rgba(100, 114, 125, 0.5);
          color: white;
        }
        tooltip {
          background: rgba(43, 48, 59, 0.5);
          border: 1px solid rgba(100, 114, 125, 0.5);
        }
        tooltip label {
          color: white;
        }
        #workspaces button {
          padding: 0 5px;
          background: transparent;
          color: white;
          border-bottom: 3px solid transparent;
        }
        #workspaces button.focused {
          background: #64727D;
          border-bottom: 3px solid white;
        }
        #mode, #clock, #battery {
          padding: 0 10px;
        }
        #mode {
          background: #64727D;
          border-bottom: 3px solid white;
        }
        #clock {
          background-color: #64727D;
        }
        #battery {
          background-color: #ffffff;
          color: black;
        }
        #battery.charging {
          color: white;
          background-color: #26A65B;
        }
        @keyframes blink {
          to {
            background-color: #ffffff;
            color: black;
          }
        }
        #battery.warning:not(.charging) {
          background: #f53c3c;
          color: white;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: steps(12);
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }
      '';
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
    dunst = {
      enable = true;
      package = pkgs.dunst;
      settings = {
        global = {
           monitor = 0;
           follow = "none";
           width = "(100, 300)";
           height = "(0, 300)";
           origin = "top-right";
           offset = "(5, 15)";
           scale = 0;
           notification_limit = 10;
           progress_bar = true;
           progress_bar_height = 14;
           progress_bar_frame_width = 0;
           progress_bar_min_width = 100;
           progress_bar_max_width = 300;
           progress_bar_corner_radius = 50;
           progress_bar_corners = "bottom-left, top-right";
           icon_corner_radius = 0;
           icon_corners = "all";
           indicate_hidden = "yes";
           transparency = 0;
           separator_height = 6;
           padding = 10;
           horizontal_padding = 8;
           text_icon_padding = 12;
           frame_width = 1;
           gap_size = 6;
           sort = "yes";
           line_height = "0";
           markup = "full";
           format = "<b>%s</b>$\n%b";
           alignment = "left";
           vertical_alignment = "center";
           show_age_threshold = -1;
           ellipsize = "middle";
           ignore_newline = "no";
           stack_duplicates = true;
           hide_duplicate_count = false;
           show_indicators = "yes";
           enable_recursive_icon_lookup = "true";
           icon_theme = "Adwaita";
           icon_position = "right";
           min_icon_size = 32;
           max_icon_size = 128;
           icon_path = "/usr/share/icons/gnome/16x16/status/:/usr/share/icons/gnome/16x16/devices/";
           sticky_history = "yes";
           history_length = 30;
           dmenu = "/usr/bin/dmenu -l 10 -p dunst:";
           browser = "/usr/bin/xdg-open";
           always_run_script = true;
           title = "Dunst";
           class = "Dunst";
           corner_radius = 10;
           corners = "bottom, top-left";
           ignore_dbusclose = false;
           force_xwayland = false;
           force_xinerama = false;
           mouse_left_click = "close_current";
           mouse_middle_click = "do_action, close_current";
           mouse_right_click = "close_all";
        };
        experimental = {
          per_monitor_dpi = false;
        };
        urgency_low = {
          timeout = 20;
        };
        urgency_normal = {
          timeout = 20;
          override_pause_level = 30;
          default_icon = "dialog-information";
        };
        urgency_critical = {
          timeout = 0;
          override_pause_level = 60;
          default_icon = "dialog-warning";
        };
      };
    };
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
