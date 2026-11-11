{ lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.supportedFilesystems.zfs = false;

  fileSystems."/" = lib.mkForce
    {
      device = "none";
      fsType = "tmpfs";
      options = [
        "size=25%"
        "mode=755"
      ];
    };

  fileSystems."/persistent" =
    {
      neededForBoot = true;
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };

  fileSystems."/nix" =
    {
      neededForBoot = true;
      device = "/persistent/nix";
      fsType = "none";
      options = [ "bind" ];
    };

  fileSystems."/boot" =
    {
      neededForBoot = true;
      device = "/persistent/boot";
      fsType = "none";
      options = [ "bind" ];
    };

  fileSystems."/boot/firmware" =
    {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      # Override the noauto added by upstream sd-image.nix
      options = lib.mkForce [ "nofail" "umask=0077" ];
    };

  swapDevices = [{
    device = "/persistent/swap/swapfile";
    size = 1 * 1024; # In MiB
  }];
  # Fix if the folder do not exists
  systemd.services.mkswap-persistent-swap-swapfile.preStart = "mkdir -p /persistent/swap";

  boot.zswap = {
    enable = true;
    compressor = "lz4";
    maxPoolPercent = 30; # Percentage of ram that can be used
    shrinkerEnabled = true; # Shrink pool when on high memory pressure
  };
  boot.kernel.sysctl."vm.swappiness" = 90; # Default is ~60

  # Some default options
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
