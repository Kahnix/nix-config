{
  flake.modules.nixos.ssh = {
    services.openssh = {
      enable = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
