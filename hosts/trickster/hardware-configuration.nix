{ lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Handled by disko
  # swapDevices = [{
  #   device = "/swap/swapfile";
  #   size = 16 * 1024; # In MiB
  # }];

  boot.zswap = {
    enable = true;
    compressor = "lz4";
    maxPoolPercent = 30; # Percentage of ram that can be used
    shrinkerEnabled = true; # Shrink pool when on high memory pressure
  };
  boot.kernel.sysctl."vm.swappiness" = 90; # Default is ~60

  powerManagement.powertop.enable = true;

  # Some default options
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
}
