{ config, ... }:

{
  imports = [ ./video-opengl.nix ];
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

  nixpkgs.config.allowUnfree = true;

  hardware.nvidia = {
    # Modesetting is required
    modesetting.enable = true;
    
    # Experimental nvidia power management
    powerManagement = {
      enable = true;
      finegrained = true; # allows to turn off the gpu while not in use
    };
    dynamicBoost.enable = true;

    # Disable the open drivers
    open = false;

    # Enable the nvidia settings menu
    nvidiaSettings = true;

    # Use the latest/stable driver version
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Enable prime gpu offload
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:198:0:0";
      nvidiaBusId = "PCI:0:1:0";
    };
  };
}
