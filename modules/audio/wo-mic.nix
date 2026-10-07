{
  unfreePackages = [ "wo-mic" ];

  # Phone as a microphone: `wo-mic PHONE_IP` plays into an ALSA loopback, and a
  # PipeWire source named WO-Mic reads the other end.
  flake.modules.nixos.wo-mic =
    { pkgs, ... }:
    {
      boot.kernelModules = [ "snd-aloop" ];
      environment.systemPackages = [ pkgs.wo-mic ];

      # WO Mic outputs 48 kHz, 16-bit mono PCM to the ALSA loopback device.
      # Keeping PipeWire at 48 kHz avoids an unnecessary resampling step.
      services.pipewire = {
        wireplumber.extraConfig."51-wo-mic-loopback" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                { "device.name" = "alsa_card.platform-snd_aloop.0"; }
              ];
              actions."update-props"."device.disabled" = true;
            }
          ];
        };
        extraConfig = {
          pipewire."10-clock-rate"."context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [ 48000 ];
          };
          pipewire-pulse."50-wo-mic-audio"."pulse.cmd" = [
            {
              cmd = "load-module";
              args = "module-alsa-source source_name=wo_mic source_properties=device.description=WO-Mic channels=1 rate=48000 format=s16le device=hw:Loopback,1,0 fragments=8 fragment_size=1920";
              flags = [ "nofail" ];
            }
          ];
        };
      };
    };
}
