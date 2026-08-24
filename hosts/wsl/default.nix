{
  pkgs,
  inputs,
  username,
  homeDirectory,
  isWSL,
  ...
}:

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
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    nano
    tailscale
  ];

  #ssh setup
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "kacper" ];
      MaxAuthTries = 3;
    };
  };
  # Needed for VS Code Remote and many random prebuilt binaries.
  programs.nix-ld.enable = true;

  services.tailscale.enable = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.extraSpecialArgs = {
    inherit
      inputs
      username
      homeDirectory
      isWSL
      ;
    isDarwin = false;
    isNixOS = false;
  };

  home-manager.users.${username} = import ../../home/${username};

  system.stateVersion = "26.05";
}
