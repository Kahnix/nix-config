{ ... }:

{
  nixpkgs.config.allowUnfreePackages = [
    "claude-code"
  ];
}
