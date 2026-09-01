{
  inputs,
  lib,
  system,
  ...
}:

let
  pkgs = inputs.nixpkgs.legacyPackages.${system};
in
{
  stylix = {
    enable = true;
    autoEnable = true;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa-dragon.yaml";

    fonts = {
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 11;
        desktop = 11;
        popups = 11;
        terminal = 12;
      };
    };

    opacity = {
      applications = 1.0;
      desktop = 0.92;
      popups = 0.92;
      terminal = 0.92;
    };
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
  };
}
