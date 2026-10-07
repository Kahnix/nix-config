{
  unfreePackages = [
    "nvidia-settings"
    "nvidia-x11"
  ];

  flake.modules.nixos.nvidia =
    { config, pkgs, ... }:
    {
      services.xserver.videoDrivers = [ "nvidia" ];
      boot = {
        blacklistedKernelModules = [ "nouveau" ];
        kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
      };

      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = [ pkgs.nvidia-vaapi-driver ];
        };

        nvidia = {
          modesetting.enable = true;
          nvidiaSettings = true;
          open = false;
          package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
          powerManagement.enable = true;
        };
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        NVD_BACKEND = "direct";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };
    };
}
