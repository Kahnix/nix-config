{
  flake.modules.homeManager.base =
    { config, ... }:
    {
      home.stateVersion = "26.11";
      programs.home-manager.enable = true;

      home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

      # `nh os switch` / `nh darwin switch` find the flake through NH_FLAKE.
      programs.nh = {
        enable = true;
        flake = "${config.home.homeDirectory}/nix-config";
      };
    };
}
