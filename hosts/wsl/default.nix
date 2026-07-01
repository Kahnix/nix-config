{ config, lib, pkgs, inputs, username, ... }:

{
  wsl.enable = true;
  wsl.defaultUser = username;

  wsl.interop.includePath = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    nano
  ];

  # Needed for VS Code Remote and many random prebuilt binaries.
  programs.nix-ld.enable = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.extraSpecialArgs = {
    inherit inputs username;
  };

  home-manager.users.${username} = import ../../home/kacper;

  system.stateVersion = "26.05";
}