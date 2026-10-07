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
  flake.modules.nixos.base = basePackages;
  flake.modules.darwin.base = basePackages;
}
