{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;
in
{
  # Noctalia: bar, launcher, control center, notifications, clipboard, OSD,
  # wallpaper, idle/lock screen and polkit agent; Noctalia Greeter for login.
  flake.modules.nixos.noctalia =
    { config, ... }:
    {
      # The screen_recorder plugin drives gpu-screen-recorder; the module adds the
      # setcap'd gsr-kms-server wrapper that direct monitor (KMS) capture needs.
      programs.gpu-screen-recorder.enable = true;

      # greetd + Noctalia Greeter, in its own wlroots compositor. The palette is
      # declared here (a complete [appearance.palette] wins over synced colours);
      # the wallpaper and monitor layout arrive through the shell's greeter sync.
      services.displayManager.noctalia-greeter = {
        enable = true;
        # Lets the shell's auto-sync run its constrained helper without a prompt.
        passwordlessSyncUsers = [ config.my.user ];
        cursorTheme = {
          inherit (config.stylix.cursor) package name;
        };
        settings = {
          session.default = "niri";
          user.default = config.my.user;

          appearance = {
            scheme = "Synced";
            theme_mode = "dark";
            corner_radius_scale = 0.85;
            font_family = config.stylix.fonts.sansSerif.name;

            palette = with config.lib.stylix.colors.withHashtag; {
              primary = base0D;
              on_primary = base00;
              secondary = base0E;
              on_secondary = base00;
              tertiary = base0C;
              on_tertiary = base00;
              error = base08;
              on_error = base00;
              surface = base00;
              on_surface = base05;
              surface_variant = base01;
              on_surface_variant = base04;
              outline = base03;
              shadow = base00;
              hover = base0C;
              on_hover = base00;
            };
          };

          idle.timeout = 300;
          cursor.size = config.stylix.cursor.size;

          keyboard = {
            layout = "us";
            numlock = true;
          };

          auth.allow_empty_password = false;
        };
      };

      home-manager.sharedModules = [ homeModules.noctalia ];
    };

  flake.modules.homeManager.noctalia =
    { config, lib, ... }:
    let
      wallpapers = "${config.home.homeDirectory}/Documents/wallpapers";
    in
    {
      # Runs noctalia.service for graphical-session.target, which niri.service
      # starts. Stylix's noctalia target adds a palette from the active scheme.
      programs.noctalia = {
        enable = true;
        systemd.enable = true;
        settings = lib.mkMerge [
          (builtins.fromTOML (builtins.readFile ./settings.toml))
          {
            wallpaper = {
              directory = wallpapers;
              default.path = "${wallpapers}/31299713726712.jpg";
            };
          }
        ];
      };
    };
}
