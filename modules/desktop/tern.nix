{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.tern = {
    home.sessionVariables.TERMINAL = "tern";
    # Tern adds every themes/NAME.css beside settings.json to its theme picker.
    xdg.configFile."tern/themes/kanagawa-dragon.css".source = ./tern-themes/kanagawa-dragon.css;
  };
  # Tern (build.stencil.so/tern) is installed outside Nix into ~/.local/bin and
  # configured through ~/.config/tern/settings.json; this provides what its
  # prebuilt glibc binary needs from the system.

  flake.modules.nixos.tern =
    { pkgs, ... }:
    {
      # It dlopens its GUI stack at runtime; nix-ld's default set has none of it.
      programs.nix-ld.libraries = pkgs.lib.mkAfter (
        with pkgs;
        [
          wayland # compositor connection
          libxkbcommon # keymap
          libglvnd # EGL/GLES for the renderer
          vulkan-loader # wgpu's Vulkan backend
          pipewire # capture/PiP plumbing
          pam # `tern remote` sign-in
          webkitgtk_4_1 # `tern browser` (wry dlopens libwebkit2gtk-4.1)
        ]
      );

      # 8376/udp: `tern remote serve` (QUIC), from my own tailnet devices only.
      # Inbound only; outbound works via conntrack.
      my.tailscale.ownDevicesOnly.allowedUDPPorts = [ 8376 ];

      # Tern's embedded WebKitGTK needs glib-networking for https.
      environment.sessionVariables.GIO_EXTRA_MODULES = [ "${pkgs.glib-networking}/lib/gio/modules" ];

      home-manager.sharedModules = [
        homeModules.tern
        {
          # `tern remote install --user` writes this unit. Without --no-iroh the
          # service also answers by endpoint id through iroh.stencil.so relays and
          # hole punching, from anywhere and around the firewall.
          xdg.configFile."systemd/user/tern-remote.service.d/no-iroh.conf".text = ''
            [Service]
            ExecStart=
            ExecStart=%h/.local/opt/tern/tern remote serve --user --state-dir %h/.config/tern --no-iroh
          '';
        }
      ];
    };
}
