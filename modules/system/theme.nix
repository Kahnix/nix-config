{ inputs, ... }:
let
  # Rosé Pine everywhere Stylix reaches; Stylix also themes the Home Manager
  # side through its Home Manager integration. Moon and Dawn are the same
  # palette with `rose-pine-moon.yaml` / `rose-pine-dawn.yaml`.
  stylix =
    { pkgs, ... }:
    {
      stylix = {
        enable = true;
        autoEnable = true;
        polarity = "dark";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";

        fonts = {
          serif = {
            package = pkgs.noto-fonts;
            name = "Noto Serif";
          };
          sansSerif = {
            package = pkgs.inter;
            name = "Inter";
          };
          # Berkeley Mono with Nerd Font icons, from the private berkeley-mono-nerd input.
          # Installs both families; "BerkeleyMono Nerd Font Mono" has one-cell icons.
          monospace = {
            package = pkgs.runCommandLocal "berkeley-mono-nerd" { } ''
              install -Dm444 -t $out/share/fonts/truetype ${inputs.berkeley-mono-nerd}/fonts/*.ttf
            '';
            name = "BerkeleyMono Nerd Font";
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
