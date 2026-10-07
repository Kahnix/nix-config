{ inputs, lib, ... }:
{
  # Enables `flake.modules.<class>.<name>`, the registry every feature file
  # writes into and every host reads from.
  imports = [ inputs.flake-parts.flakeModules.modules ];

  config.systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];

  options.unfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      Unfree package names allowed on every host and in `packages`. Feature
      files append the names they install.
    '';
  };
}
