{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;
in
{
  flake.modules.nixos.niri =
    { pkgs, ... }:
    {
      # NixOS ships niri, its "niri" session entry (niri-session -> niri.service,
      # which brings up graphical-session.target) and portals; Home Manager
      # writes the config.
      programs.niri = {
        enable = true;
        # Thunar is the file manager; GTK's file chooser instead of Nautilus.
        useNautilus = false;
      };

      environment.systemPackages = with pkgs; [
        # niri starts xwayland-satellite on demand for X11 clients (Steam,
        # Proton games) when it is on PATH.
        xwayland-satellite
        niri-focus-or-spawn
      ];

      programs.dconf.enable = true;
      security.polkit.enable = true;

      # The niri module routes Access, FileChooser and Notification to GTK but
      # only installs the GNOME portal (screencast).
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

      environment.sessionVariables = {
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        NIXOS_OZONE_WL = "1";
        # AWT under Xwayland on a non-reparenting compositor: without this, Swing
        # frames (RuneLite) never pick up resizes and paint at their initial size.
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };

      home-manager.sharedModules = [ homeModules.niri ];
    };

  flake.modules.homeManager.niri =
    { config, pkgs, ... }:
    let
      colors = config.lib.stylix.colors.withHashtag;
    in
    {
      # niri reloads the file live when the symlink changes.
      xdg.configFile."niri/config.kdl".source =
        pkgs.runCommand "niri-config.kdl" { nativeBuildInputs = [ pkgs.niri ]; } ''
          substitute ${./config.kdl} $out \
            --subst-var-by base02 '${colors.base02}' \
            --subst-var-by base0C '${colors.base0C}' \
            --subst-var-by base0D '${colors.base0D}'
          niri validate -c $out
        '';
    };
}
