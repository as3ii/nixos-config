{ config, lib, ... }:

let
  IDType = lib.types.strMatching "(PCI:[0-9]{1,3}:[0-9]{1,2}:[0-9])?";
  cfg = config.nvidia;
in
{
  options.nvidia = {
    amdId = lib.mkOption {
      type = IDType;
      default = "";
      example = "PCI:1:0:0";
      description = ''
        Bus ID of the Nvidia GPU. Run lspci and convert the hex numbers to decimal;
        for example if lspci shows the AMD APU at "01:00.0", set this option to
        "PCI:1:0:0".
      '';
    };

    intelId = lib.mkOption {
      type = IDType;
      default = "";
      example = "PCI:2:0:0";
      description = ''
        Bus ID of the Intel iGPU. Run lspci and convert the hex numbers to decimal;
        for example if lspci shows the Intel iGPU at "02:00.0", set this option to
        "PCI:2:0:0".
      '';
    };

    nvidiaId = lib.mkOption {
      type = IDType;
      default = "";
      example = "PCI:3:0:0";
      description = ''
        Bus ID of the Nvidia GPU. Run lspci and convert the hex numbers to decimal;
        for example if lspci shows the Nvidia GPU at "03:00.0", set this option to
        "PCI:3:0:0".
      '';
    };

    enablePrimeSync = lib.mkEnableOption ''
      Enable Prime Sync specialisation.
    '';
  };

  config = {
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
      "nouveau"
      "nvidia"
      "nvidia_drm"
      "nvidia_modeset"
    ];

    specialisation = {
      # Nvidia offload specialisation
      nvidia-offload.configuration = {
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
            amdgpuBusId = cfg.amdId;
            intelBusId = cfg.intelId;
            nvidiaBusId = cfg.nvidiaId;
          };
        };

        # load nvidia driver after amdgpu
        services.xserver.videoDrivers = lib.mkAfter [ "nvidia" ];
      };

      # Nvidia sync specialisation
      nvidia-sync.configuration = lib.mkIf cfg.enablePrimeSync {
        hardware.nvidia = {
          modesetting.enable = true;
          powerManagement.enable = true;
          dynamicBoost.enable = true;
          open = lib.versionAtLeast config.hardware.nvidia.package.version "560";
          prime = {
            sync.enable = true;
            # GPU Bus ID, converted from hex to decimal
            amdgpuBusId = cfg.amdId;
            intelBusId = cfg.intelId;
            nvidiaBusId = cfg.nvidiaId;
          };
        };

        # load nvidia driver before amdgpu
        services.xserver.videoDrivers = lib.mkBefore [ "nvidia" ];
      };
    };
  };
}

# vim: sw=2
