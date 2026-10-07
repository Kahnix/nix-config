{
  # Needed for VS Code Remote and many prebuilt binaries; features that ship
  # such binaries append to programs.nix-ld.libraries.
  flake.modules.nixos.nix-ld.programs.nix-ld.enable = true;
}
