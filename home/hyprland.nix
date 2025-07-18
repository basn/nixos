{  pkgs, ... }:
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
          "height" = 42; 
          "spacing" = 3;
          "modules-left" = [
            "hyprland/workspaces"
          ];
          "modules-center" = [
            "hyprland/window"
          ];
          "modules-right" = [
            "custom/waybar-mpris"
            "cpu"
            "memory"
            "pulseaudio"
            "clock"
            "tray"
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
          "custom/waybar-mpris" = {
            "return-type" = "json";
            "exec" = "waybar-mpris --position --autofocus";
            "on-click" = "waybar-mpris --send toggle";
            "escape" ="true";
          };
        }
      ];
      style = ''
        * {
          font-family: "MesloLGS NF";
          font-weight: bold;
          font-size: 10px;
          color: #dcdfe1;
        }
        #waybar {
          background-color: rgba(0, 0, 0, 0);
          border: none;
          box-shadow: none;
        }
        #workspaces,
        #window,
        #tray{
          background-color: rgba(15,27,53,0.9);
          padding: 4px 6px;
          margin-top: 1px;
          margin-left: 6px;
          margin-right: 6px;
          border-radius: 5px;
          border-width: 0px;
        }
        #clock,
        #custom-power{
          background-color: rgba(15,27,53,0.9);
          margin-top: 6px; 
          margin-right: 6px;
          padding: 4px 2px;
          border-radius: 0 10px 10px 0;
          border-width: 0px;
        }
        #network,
        #custom-lock{
          background-color: rgba(15,27,53,0.9);
          margin-top: 6px;
          margin-left: 6px;
          padding: 4px 2px;
          border-radius: 5px 0 0 10px;
          border-width: 0px;
        }
        #custom-reboot,
        #bluetooth,
        #battery,
        #pulseaudio,
        #backlight,
        #custom-waybar-mpris {
          background-color: rgba(15,27,53,0.9);
          padding: 4px 6px;
          margin-top: 6px;
          border-width: 0px;        
        }
        #memory,
        #cpu{
          background-color: rgba(15,27,53,0.9);
          margin-top: 6px;
          padding: 4px 2px;
          border-width: 0px;
        }
        #custpm-temperature.critical,
        #pulseaudio.muted {
          color: #FF0000;
          padding-top: 0;
        }
        #bluetooth:hover,
        #network:hover,
        #backlight:hover,
        #battery:hover,
        #pulseaudio:hover,
        #custom-temperature:hover,
        #memory:hover,
        #cpu:hover,
        #clock:hover,
        #custom-lock:hover,
        #custom-reboot:hover,
        #custom-power:hover,
        /*#workspaces:hover,*/
        #window:hover {
          background-color: rgba(70, 75, 90, 0.9);
        }
        #workspaces button:hover{
          background-color: rgba(97, 175, 239, 0.2);
          padding: 2px 8px;
          margin: 0 2px;
          border-radius: 5px;
        }
        #workspaces button.active {
          background-color: #61afef;
          color: #ffffff;
          padding: 2px 8px;
          margin: 0 2px;
          border-radius: 5px;
        }
        #workspaces button {
          background: transparent;
          border: none;
          color: #888888;
          padding: 2px 8px;
          margin: 0 2px;
          font-weight: bold;
        }
        #window {
          font-weight: 500;
          font-style: italic;
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
    hyprpaper = {
      enable = true;
      settings = {
        preload = [ "/home/basn/nixos.png" ];
        wallpaper = [ ",/home/basn/nixos.png" ];
      };
    };
  };
  #stylix.targets.waybar.addCss = false;
}
