{
  flake.modules.nixos.ssh = {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
