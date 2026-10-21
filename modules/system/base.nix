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

  caTrust = {
    environment.variables.NODE_OPTIONS = "--use-openssl-ca";
  };
in
{
  flake.modules.nixos.base = {
    imports = [
      basePackages
      caTrust
    ];
  };
  flake.modules.darwin.base = basePackages;
}
