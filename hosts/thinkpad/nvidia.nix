{ config, lib, input, ... }:

let
  amdId = "PCI:198:0:0";
  nvidiaId = "PCI:0:1:0";
in
{
  # Blacklist nvidia by default
  boot.extraModprobeConfig = lib.mkIf (! builtins.elem "nvidia" config.services.xserver.videoDrivers) ''
    blacklist nouveau
    options nouveau modeset=0
  '';
  services.udev.extraRules = lib.mkIf (! builtins.elem "nvidia" config.services.xserver.videoDrivers) ''
    # Remove NVIDIA USB xHCI Host Controller devices, if present
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
    # Remove NVIDIA USB Type-C UCSI devices, if present
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
    # Remove NVIDIA Audio devices, if present
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
    # Remove NVIDIA VGA/3D controller devices
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
  '';
  boot.blacklistedKernelModules = lib.mkIf (! builtins.elem "nvidia" config.services.xserver.videoDrivers) [
    "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset"
  ];

  # Nvidia offload specialisation
  specialisation.nvidia-offload.configuration = {
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      dynamicBoost.enable = true;
      open = lib.versionAtLeast config.hardware.nvidia.package.version "560";
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

    # load nvidia driver after amdgpu
    services.xserver.videoDrivers = lib.mkAfter [ "nvidia" ];
  };

  # Nvidia sync specialisation
  specialisation.nvidia-sync.configuration = {
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      dynamicBoost.enable = true;
      open = lib.versionAtLeast config.hardware.nvidia.package.version "560";
      prime = {
        sync.enable = true;
        # GPU Bus ID, converted from hex to decimal
        amdgpuBusId = amdId;
        nvidiaBusId = nvidiaId;
      };
    };

    # load nvidia driver before amdgpu
    services.xserver.videoDrivers = lib.mkBefore [ "nvidia" ];
  };
}

# vim: sw=2
