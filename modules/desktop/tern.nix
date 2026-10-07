{
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

      # 8376/udp: `tern remote serve` (QUIC). Inbound only; outbound works via conntrack.
      networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 8376 ];

      # Tern's embedded WebKitGTK needs glib-networking for https.
      environment.sessionVariables.GIO_EXTRA_MODULES = [ "${pkgs.glib-networking}/lib/gio/modules" ];

      home-manager.sharedModules = [ { home.sessionVariables.TERMINAL = "tern"; } ];
    };
}
