{ input, ... }:

{
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    dynamicBoost.enable = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # GPU Bus ID, converted from hex to decimal
      amdgpuBusId = "PCI:198:0:0";
      nvidiaBusId = "PCI:0:1:0";
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}

# vim: sw=2
