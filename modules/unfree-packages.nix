{ ... }:

{
  nixpkgs.config.allowUnFreePackages = [
    "claude-code"
  ];
}
