final: prev:

let
  nodejsPath = "${prev.path}/pkgs/development/web/nodejs";
  callNodejsPackage =
    path: args:
    final.callPackage path (
      args
      // prev.lib.optionalAttrs (baseNameOf path == "nodejs.nix") {
        stdenv = final.buildPackages.llvmPackages_20.libcxxStdenv;
      }
    );
  fixedNodejsSlim24 = import "${nodejsPath}/v24.nix" {
    inherit (final)
      buildPackages
      fetchpatch2
      lib
      openssl
      python3
      stdenv
      ;
    callPackage = callNodejsPackage;
  };
  fixedNodejs24 = final.callPackage "${nodejsPath}/symlink.nix" {
    nodejs-slim = fixedNodejsSlim24;
  };
in
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  nodejs-slim_24 = fixedNodejsSlim24;
  nodejs_24 = fixedNodejs24;

  nodejs-slim = fixedNodejsSlim24;
  nodejs = fixedNodejs24;

  corepack_24 = final.callPackage "${nodejsPath}/corepack.nix" {
    nodejs = fixedNodejsSlim24;
  };

  pnpm_11 = prev.pnpm_11.override {
    nodejs-slim = fixedNodejsSlim24;
  };
  pnpm = final.pnpm_11;
}
