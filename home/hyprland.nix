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
          font-family: "MesloLGS NF";
          font-size: 10px;
          border-radius: 0;
          min-height: 0;
          border: none;
          font-weight: bold;
        }
        #workspaces{
          background-color: rgba(24,24,37,1.0);
          border: none;
          box-shadow: none;
        }
        #tray{
          margin: 6px 3px;
          background-color: rgba(36, 36, 52, 1.0);
          padding: 6px 10px;
          border-radius: 6px;
          border-width: 0px;
        }
        #waybar {
          background-color: #181825;
          transition-property: background-color;
          transition-duration: 0.5s;
        }
        #window,
        #clock,
        #custom-power,
        #custom-reboot,
        #bluetooth,
        #battery,
        #pulseaudio,
        #backlight,
        #custom-temperature,
        #memory,
        #cpu,
        #network,
        #custom-lock{
          border-radius: 4px;
          margin: 6px 3px;
          padding: 6px 12px;
          background-color: #1e1e2e;
          color: #181825;
        }
        #clock {
          background-color: #89b4fa;
        }
        #custom-power{
          background-color: #f38ba8;
        }
        #custom-reboot{
          background-color: #a6e3a1;
        }
        #bluetooth{
          background-color: #f9e2af;
        }
        #battery{
          background-color: #cba6f7;
        }
        #pulseaudio{
          background-color: #89dceb;
        }
        #backlight{
          background-color: #a6a3a1;
        }
        #custom-temperature{
          background-color: #74c7ec;
        }
        #memory{
          background-color: #f7768e;
        }
        #cpu{
          background-color: #f38ba8;
        }
        #network{
          background-color: #fab387;
        }
        #custom-lock{
          background-color: #94e2d5;
        }
        #window{
          background-color: #74c7ec;
        }
        #waybar.hidden {
          opacity: 0.5;
        }
        #workspaces button {
          all: initial;
          /* Remove GTK theme values (waybar #1351) */
          min-width: 0;
          /* Fix weird spacing in materia (waybar #450) */
          box-shadow: inset 0 -3px transparent;
          /* Use box-shadow instead of border so the text isn't offset */
          padding: 6px 10px;
          margin: 6px 3px;
          border-radius: 4px;
          background-color: rgba(36, 36, 52, 1.0);
          color: #cdd6f4;
        }
        #workspaces button.active {
          color: #1e1e2e;
          background-color: #cdd6f4;
        }
        #workspaces button:hover {
          box-shadow: inherit;
          text-shadow: inherit;
          color: #1e1e2e;
          background-color: #cdd6f4;
        }
        tooltip {
          border-radius: 8px;
          padding: 16px;
          background-color: #131822;
          color: #C0C0C0;
        }
        tooltip label {
          padding: 5px;
          background-color: #131822;
          color: #C0C0C0;
        }
      '';
    };
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      extraConfig = {
        modes = [ "combi" ];
        combi-modes = [ "window" "drun" "run" ];
        show-icons = true;
        matching = "fuzzy";
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
          ignore_dbus_inhibit = true;
          lock_cmd = "pidof hyprlock || hyprlock";
          };
        listener = [
          {
            timeout = 250;
            on-timeout = "pidof hyprlock || hyprlock";
          }
          {
            timeout = 250;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
  };
}
