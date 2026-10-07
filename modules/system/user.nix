{ config, inputs, ... }:
let
  # Home Manager modules every host's user gets; host and feature modules add
  # more through home-manager.sharedModules or home-manager.users.<name>.
  homeModules = with config.flake.modules.homeManager; [
    base
    dev
    shell
  ];

  homeManagerSettings = user: {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-home-manager";
    users.${user}.imports = homeModules;
  };
in
{
  flake.modules.nixos.user =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      options.my.user = lib.mkOption {
        type = lib.types.str;
        default = "kacper";
        description = "Login account that Home Manager configures.";
      };

      config = {
        users.users.${config.my.user} = {
          isNormalUser = true;
          shell = pkgs.fish;
          extraGroups = [ "wheel" ];
        };
        programs.fish.enable = true;

        home-manager = homeManagerSettings config.my.user;
      };
    };

  flake.modules.darwin.user =
    { config, pkgs, ... }:
    let
      user = config.system.primaryUser;
    in
    {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      users.users.${user}.home = "/Users/${user}";

      # The macOS admin account is owned by macOS rather than nix-darwin.
      # Register Fish here, then select it once with:
      #   chsh -s /run/current-system/sw/bin/fish
      programs.fish.enable = true;
      environment.shells = [ pkgs.fish ];

      home-manager = homeManagerSettings user;
    };
}
