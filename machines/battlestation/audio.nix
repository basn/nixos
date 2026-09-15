{ ... }:
let
  baseUdevRules = ''
    # Prevent autosuspend on Fosi Audio K7 USB DAC to avoid audio crackle/dropouts.
    ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="152a", ATTR{idProduct}=="889b", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="152a", ATTR{idProduct}=="889b", TEST=="power/autosuspend_delay_ms", ATTR{power/autosuspend_delay_ms}="-1"
    # Prevent autosuspend on Elgato Wave XLR to avoid mute/unmute wakeup glitches.
    ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{product}=="Wave XLR", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{product}=="Wave XLR", TEST=="power/autosuspend_delay_ms", ATTR{power/autosuspend_delay_ms}="-1"
  '';
in
{
  services = {
    udev.extraRules = baseUdevRules;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      wireplumber.extraConfig = {
        "50-fosi-k7-pro-device" = {
          "monitor.alsa.rules" = [
            {
              matches = [ { "device.name" = "~alsa_card.usb-Fosi_Audio_Fosi_Audio_K7.*"; } ];

              actions.update-props = {
                # Prefer this card when selecting default audio devices.
                "priority.session" = 2000;
                "priority.driver" = 2000;

                # Disable DSD unless explicitly requested.
                "api.alsa.disable-dsd" = true;
              };
            }
          ];
        };
        "51-fosi-k7-pro-node" = {
          "monitor.alsa.rules" = [
            {
              matches = [ { "node.name" = "~alsa_output.usb-Fosi_Audio_Fosi_Audio_K7-00.pro-output-0"; } ];
              actions.update-props = {
                # Apply playback format and adaptive rate behavior on the sink node.
                "priority.session" = 2000;
                "priority.driver" = 2000;
                "audio.format" = "S32LE";
                "audio.channels" = 2;
                "audio.position" = [
                  "FL"
                  "FR"
                ];
                # Allow rate switching to match source material when possible.
                "api.alsa.multi-rate" = true;
                "audio.allowed-rates" = [
                  44100
                  48000
                  88200
                  96000
                  176400
                  192000
                ];
              };
            }
          ];
        };
        "52-wave-xlr-source-node" = {
          "monitor.alsa.rules" = [
            {
              # Keep Wave XLR capture active so hardware unmute reliably resumes capture.
              matches = [ { "node.name" = "~alsa_input.usb-.*Wave_XLR.*"; } ];
              actions.update-props = {
                "session.suspend-timeout-seconds" = 0;
                "node.pause-on-idle" = false;
              };
            }
          ];
        };
      };
    };
  };

  security.rtkit.enable = true;
}
