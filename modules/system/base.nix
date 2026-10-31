let
  basePackages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        curl
        git
        wget
      ];
    };
in
{
  flake.modules.nixos.base = {
    imports = [
      basePackages
    ];
  };
  flake.modules.darwin.base = basePackages;
}
