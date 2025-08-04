{ ... }:
{
  services = {
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
