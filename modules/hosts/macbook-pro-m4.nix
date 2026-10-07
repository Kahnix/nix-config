{ config, inputs, ... }:
let
  modules = config.flake.modules.darwin;
  homeModules = config.flake.modules.homeManager;
in
{
  flake.darwinConfigurations.macbook-pro-m4 = inputs.darwin.lib.darwinSystem {
    modules = with modules; [
      host-macbook-pro-m4

      base
      nix
      user
      theme
    ];
  };

  flake.modules.darwin.host-macbook-pro-m4 =
    { config, pkgs, ... }:
    {
      nixpkgs.hostPlatform = "aarch64-darwin";
      system.primaryUser = "kacperdaniel";

      # Keep the native macOS menu bar visible.
      system.defaults.NSGlobalDomain._HIHideMenuBar = false;
      system.defaults.spaces.spans-displays = false;
      system.defaults.CustomUserPreferences."com.apple.controlcenter".AutoHideMenuBarOption = 3;

      environment.systemPackages = [ pkgs.nano ];

      home-manager.users.${config.system.primaryUser} =
        { config, pkgs, ... }:
        let
          androidSdk = "${config.home.homeDirectory}/Library/Android/sdk";
        in
        {
          imports = [ homeModules.darwin-desktop ];

          # Android / React Native toolchain.
          home.packages = with pkgs; [
            jdk17
            watchman
          ];
          home.sessionVariables = {
            ANDROID_HOME = androidSdk;
            ANDROID_SDK_ROOT = androidSdk;
            JAVA_HOME = pkgs.jdk17.home;
          };
          home.sessionPath = [
            "${androidSdk}/emulator"
            "${androidSdk}/platform-tools"
            "${androidSdk}/cmdline-tools/latest/bin"
          ];

          programs.fish.shellAliases.rebuild = "nh darwin switch -H macbook-pro-m4";
        };

      system.stateVersion = 6;
    };
}
