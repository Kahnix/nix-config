{ inputs, ... }:
let
  # Kanagawa Dragon everywhere Stylix reaches; Stylix also themes the Home
  # Manager side through its Home Manager integration.
  stylix =
    { pkgs, ... }:
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
            terminal = 9;
          };
        };

        opacity = {
          applications = 1.0;
          desktop = 0.92;
          popups = 0.92;
          terminal = 1.0;
        };
      };
    };
in
{
  flake.modules.nixos.theme =
    { pkgs, ... }:
    {
      imports = [
        inputs.stylix.nixosModules.stylix
        stylix
      ];
      # nix-darwin's Stylix has no cursor option.
      stylix.cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
      };
    };
  flake.modules.darwin.theme = {
    imports = [
      inputs.stylix.darwinModules.stylix
      stylix
    ];
  };
}
