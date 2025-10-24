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

  fileSystems."/" =
    {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };

  fileSystems."/boot/firmware" =
    {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };

  swapDevices = [{ device = "/swap/swapfile"; }];
  zramSwap = {
    enable = true;
    priority = 10;
    algorithm = "zstd";
  };
  # Drastically reduce latency and increase IOPS (but reduces raw speed) when using zram+zstd
  # This may reduce the performance of on-disk swap
  # See: https://notes.xeome.dev/notes/Zram#conclusion
  boot.kernel.sysctl."vm.page-cluster" = 0; # Default value: 3

  # Some default options
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
