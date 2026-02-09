{ config, lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" "ntsync" ];
  boot.extraModulePackages = [ ];

  # root luks FS
  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/2b85c77d-fd5e-42aa-a2e0-0e8694a162d6";

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" "compress=zstd:2" "autodefrag" "subvol=@" ];
    };

  fileSystems."/btrfs_root" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" "autodefrag" ];
    };

  fileSystems."/snapshot" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" "compress=zstd:2" "autodefrag" "subvol=@snapshot" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" "compress=zstd:2" "autodefrag" "subvol=@home" ];
    };

  fileSystems."/root" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" "compress=zstd:2" "autodefrag" "subvol=@root" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" "compress=zstd:2" "autodefrag" "subvol=@nix" ];
    };

  fileSystems."/swap" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" "autodefrag" "subvol=@swap" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/7C50-69E2";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };

  swapDevices = [{ device = "/swap/swapfile"; }];
  # Hibernation stuff
  boot.resumeDevice = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
  boot.kernelParams = [ "resume_offset=103867648" ];
  powerManagement.enable = true;

  zramSwap = {
    enable = true;
    priority = 10;
    algorithm = "zstd";
  };
  # Drastically reduce latency and increase IOPS (but reduces raw speed) when using zram+zstd
  # This may reduce the performance of on-disk swap
  # See: https://notes.xeome.dev/notes/Zram#conclusion
  boot.kernel.sysctl."vm.page-cluster" = 0; # Default value: 3

  services = {
    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = [ "/" ];
    };
    btrbk = {
      instances."btrbk" = {
        onCalendar = "Mon,Thu *-*-*"; # 2 times a week
        settings = {
          timestamp_format = "long";
          snapshot_preserve = "6d 2w 1m";
          snapshot_preserve_min = "6d";
          snapshot_create = "always";
          incremental = "yes";
          target_preserve = "7d 3w 2m";
          target_preserve_min = "8d";
          stream_compress = "zstd";
          stream_compress_level = "default";
          stream_compress_long = "default";
          send_protocol = "2";
          volume."/btrfs_root" = {
            snapshot_dir = "@snapshot";
            target = "/mnt/veracrypt2/snapshot";
            subvolume = {
              "@home" = { };
              "@" = { };
            };
          };
        };
      };
    };
  };

  # Some default options
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
