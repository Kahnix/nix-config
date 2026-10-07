{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;
in
{
  # ShadowPlay-style replay buffer: Super+Alt+R saves the last 60 s,
  # Super+Alt+Shift+R toggles the buffer.
  flake.modules.nixos.replay-buffer =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # Installs the CLI plus a setcap'd gsr-kms-server wrapper, which direct
      # monitor (KMS) capture requires.
      programs.gpu-screen-recorder.enable = true;

      # Free the GPU from the buffer while a game runs.
      programs.gamemode.settings.custom = lib.mkIf config.programs.gamemode.enable {
        start = "${lib.getExe pkgs.gsr-gamemode-hook} start";
        end = "${lib.getExe pkgs.gsr-gamemode-hook} end";
      };

      home-manager.sharedModules = [ homeModules.replay-buffer ];
    };

  flake.modules.homeManager.replay-buffer =
    { config, pkgs, ... }:
    {
      home.packages = [ pkgs.gsr-replay ];

      # Capture goes through KMS (gsr-kms-server), so it never waits on a portal
      # dialog; SIGINT is GSR's "exit cleanly" signal.
      systemd.user.services.gsr-replay = {
        Unit = {
          Description = "GPU Screen Recorder replay buffer";
          PartOf = [ config.wayland.systemd.target ];
          # KMS capture needs the graphical session and its outputs to be available.
          After = [ config.wayland.systemd.target ];
        };

        Service = {
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/Videos/Replays";
          # NVENC is unusable on this driver (it reports NVENC API 13.0, ffmpeg wants
          # 13.1), so encode with Vulkan Video instead; switch to h264_software if it
          # misbehaves. One output only: with a second monitor attached, use
          # "-w HDMI-A-2" or "-w focused" instead of "-w screen".
          # Single line on purpose: Home Manager renders a list as one ExecStart=
          # per element, which systemd rejects for non-oneshot services.
          ExecStart = "${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder -w screen -f 60 -k h264_vulkan -c mp4 -r 60 -a default_output -o %h/Videos/Replays -ipc %t/gsr.sock";
          Restart = "on-failure";
          RestartSec = 5;
          KillSignal = "SIGINT";
        };

        Install.WantedBy = [ config.wayland.systemd.target ];
      };
    };
}
