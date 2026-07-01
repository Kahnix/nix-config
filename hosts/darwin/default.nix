{
  pkgs,
  inputs,
  system,
  username,
  homeDirectory,
  ...
}:

{
  nixpkgs.hostPlatform = system;

  system.primaryUser = username;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users.${username} = {
    home = homeDirectory;
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    nano
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "before-home-manager";

  home-manager.extraSpecialArgs = {
    inherit inputs username homeDirectory;
  };

  home-manager.users.${username} = import ../../home/kacper;

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 6;
}
