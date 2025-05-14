{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

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

  # Some default options
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
