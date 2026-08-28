{ pkgs, ... }:

{
  programs.virt-manager.enable = true;

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;
        swtpm.enable = true;
      };
    };

    spiceUSBRedirection.enable = true;
  };

  environment.systemPackages = with pkgs; [
    quickemu
    spice-gtk
    virtiofsd
  ];
}
