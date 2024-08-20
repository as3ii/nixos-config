{ lib, input, ... }:

let
  amdId = "PCI:198:0:0";
  nvidiaId = "PCI:0:1:0";
in
{
  specialisation.nvidia-offload.configuration = {
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
        amdgpuBusId = amdId;
        nvidiaBusId = nvidiaId;
      };
    };

    services.xserver.videoDrivers = lib.mkAfter [ "nvidia" ];
  };

  specialisation.nvidia-sync.configuration = {
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      dynamicBoost.enable = true;
      prime = {
        sync.enable = true;
        # GPU Bus ID, converted from hex to decimal
        amdgpuBusId = amdId;
        nvidiaBusId = nvidiaId;
      };
    };

    services.xserver.videoDrivers = lib.mkAfter [ "nvidia" ];
  };
}

# vim: sw=2
