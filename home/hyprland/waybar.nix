{ pkgs, ... }:
{
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
            "idle_inhibitor"
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
            "format" = "{:%T}";
            "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            "format-alt" = "{:%Y-%m-%d}";
            "interval" = 1;
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
          font-weight: normal;
          font-size: 10px;
          color: #dcdfe1;
        }
        #waybar {
          background-color: rgba(15, 27, 53, 0.9);
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
          border-radius: 0 10px 10px 0;
          border-width: 0px;        
        }
        #idle_inhibitor {
          background-color: rgba(15,27,53,0.9); 
          padding: 4px 6px;
          margin-top: 6px;
          margin-left: 6px;
          border-radius: 0 10px 10px 0;
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
  };
  #stylix.targets.waybar.addCss = false;
}
