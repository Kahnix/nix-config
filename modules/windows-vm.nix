{
  # `winvm`: Windows 11 VM for building/testing the Windows app. QEMU/HVF on the
  # Apple Silicon Mac (ARM64 guest), QEMU/KVM on the desktop (x64 guest).
  flake.modules.darwin.windows-vm =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.winvm ];
    };

  flake.modules.nixos.windows-vm =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.winvm ];
      users.users.${config.my.user}.extraGroups = [ "kvm" ];
    };
}
