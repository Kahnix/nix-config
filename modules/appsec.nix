{
  # CodeQL CLI: GitHub CodeQL Terms and Conditions.
  unfreePackages = [ "codeql" ];

  # Application-security tooling beside the dev setup, on every host.
  flake.modules.homeManager.dev =
    { lib, pkgs, ... }:
    {
      home.packages =
        with pkgs;
        [
          # semgrep is left out: nixpkgs' 1.180.0 fails to build (patchelf) and,
          # once patched, crashes on import against mcp 2.x.
          codeql # data-flow queries; also the language server for .ql files
          ast-grep # structural search and rewrite (sg)
          nuclei # templated web scanning
          ffuf # web fuzzing
        ]
        # gdb can't debug natively on Apple silicon (lldb covers macOS), and
        # strace/ltrace are Linux syscalls/ELF only.
        ++ lib.optionals stdenv.hostPlatform.isLinux [
          gdb
          gef # exploit-dev gdb extension (pwndbg isn't in nixpkgs): gef ./binary
          strace
          ltrace
        ];
    };
}
