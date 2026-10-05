{
  pkgs,
  inputs,
  system,
  username,
  homeDirectory,
  isDarwin,
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

    # kacper@nixos: lets the NixOS machine ssh in (herdr machine add from nixos).
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMr2TNbEMNm9eshwXm+0r+pXT4k9JaYXrFcamfOTYU/8 kacpe@Experian"
    ];
  };

  # Remote Login (Apple's sshd), key-only. Reachable over Tailscale as
  # kacpers-macbook-pro.
  services.openssh = {
    enable = true;
    extraConfig = ''
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      PermitRootLogin no
    '';
  };

  programs.fish.enable = true;

  # The existing macOS admin account is owned by macOS rather than nix-darwin.
  # Register Fish here, then select it once with:
  #   chsh -s /run/current-system/sw/bin/fish
  environment.shells = [ pkgs.fish ];

  # Keep the native macOS menu bar visible.
  system.defaults.NSGlobalDomain._HIHideMenuBar = false;
  system.defaults.spaces.spans-displays = false;
  system.defaults.CustomUserPreferences."com.apple.controlcenter".AutoHideMenuBarOption = 3;

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
    inherit
      inputs
      username
      homeDirectory
      isDarwin
      ;
    isNixOS = false;
    isWSL = false;
  };

  home-manager.users.${username} = import ../../home/kacper;

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 6;
}
