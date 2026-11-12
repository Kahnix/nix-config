{ inputs, ... }:
let
  # Gruvbox Paper everywhere Stylix reaches; Stylix also themes the Home
  # Manager side through its Home Manager integration.
  stylix =
    { pkgs, lib, ... }:
    {
      stylix = {
        enable = true;
        autoEnable = true;
        polarity = "dark";
        base16Scheme = ./gruvbox-paper.yaml;

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
            # Noto 3D emoji (googlefonts/noto-emoji 3D/fonts), pinned to a commit.
            # Its internal family is "Noto Color Emoji", so the name below is unchanged.
            package = pkgs.runCommandLocal "noto-3d-emoji" { } ''
              install -Dm444 -t $out/share/fonts/truetype ${pkgs.fetchurl {
                url = "https://media.githubusercontent.com/media/googlefonts/noto-emoji/1ffdd21391dd1f25c081fa93a9dea0c7c029442b/3D/fonts/Noto-3D-128.ttf";
                hash = "sha256-b0MSp8AtDJ3ogJXuZeMg/+kxbS2NVuTFFecYH8pe1Dk=";
              }}
            '';
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

      # Helix only: drop the editor background so the terminal shows through.
      # Stylix derives this from opacity.terminal at normal priority, hence mkForce.
      home-manager.sharedModules = [ { stylix.targets.helix.transparent = lib.mkForce true; } ];
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
