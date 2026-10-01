{ pkgs, ... }:

{
  programs.virt-manager.enable = true;

  virtualisation = {
    # Container runtime for local Compose stacks (SilentLeads Postgres/MinIO/Keycloak).
    # pkgs.docker bundles the buildx and compose CLI plugins, so `docker compose` works.
    docker.enable = true;

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
