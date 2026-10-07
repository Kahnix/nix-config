{ config, inputs, ... }:
let
  modules = config.flake.modules.nixos;
in
{
  flake.nixosConfigurations.wsl = inputs.nixpkgs.lib.nixosSystem {
    modules = with modules; [
      host-wsl

      base
      nix
      user
      ssh
      tailscale
      nix-ld
    ];
  };

  flake.modules.nixos.host-wsl =
    { config, pkgs, ... }:
    {
      imports = [ inputs.nixos-wsl.nixosModules.default ];

      nixpkgs.hostPlatform = "x86_64-linux";

      wsl = {
        enable = true;
        defaultUser = config.my.user;
        interop.includePath = true;
      };

      # Key-only, single-user SSH on top of the shared ssh module.
      services.openssh.settings = {
        PasswordAuthentication = false;
        AllowUsers = [ config.my.user ];
        MaxAuthTries = 3;
      };

      environment.systemPackages = [ pkgs.nano ];

      home-manager.users.${config.my.user}.programs.fish.shellAliases.rebuild = "nh os switch -H wsl";

      system.stateVersion = "26.05";
    };
}
