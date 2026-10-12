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
      options = [ "discard=async" "noatime" "compress=zstd:2" "subvol=@" ];
    };

  fileSystems."/btrfs_root" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" ];
    };

  fileSystems."/snapshot" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" "compress=zstd:2" "subvol=@snapshot" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" "compress=zstd:2" "subvol=@home" ];
    };

  fileSystems."/root" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" "compress=zstd:2" "subvol=@root" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" "compress=zstd:2" "subvol=@nix" ];
    };

  fileSystems."/swap" =
    {
      device = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
      fsType = "btrfs";
      options = [ "discard=async" "noatime" "subvol=@swap" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/7C50-69E2";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };

  swapDevices = [{ device = "/swap/swapfile"; }];

  boot.zswap = {
    enable = true;
    compressor = "lz4";
    maxPoolPercent = 30; # Percentage of ram that can be used
    shrinkerEnabled = true; # Shrink pool when on high memory pressure
  };
  boot.kernel.sysctl."vm.swappiness" = 90; # Default is ~60

  # Hibernation stuff
  boot.resumeDevice = "/dev/disk/by-uuid/671620d3-6b9f-412f-8e0f-1baaf599156c";
  boot.kernelParams = [
    "resume_offset=103867648"
  ];
  powerManagement.enable = true;

  services = {
    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = [ "/" ];
    };
    btrbk =
      let
        onCalendar = "Mon,Thu *-*-*";
        timestamp_format = "long";
        snapshot_preserve = "6d 2w 1m";
        snapshot_preserve_min = "6d";
        incremental = "yes";
        target_preserve = "7d 3w 2m";
        target_preserve_min = "8d";
        snapshot_dir = "@snapshot";
        volume = "/btrfs_root";
        subvolume = {
          "@home" = { };
          "@" = { };
        };
        target = "/mnt/veracrypt2/snapshot";
      in
      {
        instances."btrbk" = {
          onCalendar = onCalendar; # 2 times a week
          settings = {
            timestamp_format = timestamp_format;
            snapshot_preserve = snapshot_preserve;
            snapshot_preserve_min = snapshot_preserve_min;
            incremental = incremental;
            snapshot_create = "onchange";
            volume."${volume}" = {
              snapshot_dir = snapshot_dir;
              subvolume = subvolume;
            };
          };
        };
        instances."btrbk-remote" = {
          onCalendar = onCalendar; # 2 times a week
          settings = {
            timestamp_format = timestamp_format;
            snapshot_preserve = snapshot_preserve;
            snapshot_preserve_min = snapshot_preserve_min;
            incremental = incremental;
            snapshot_create = "no";
            target_preserve = target_preserve;
            target_preserve_min = target_preserve_min;
            stream_compress = "zstd";
            stream_compress_level = "default";
            stream_compress_long = "default";
            send_protocol = "2";
            volume."${volume}" = {
              snapshot_dir = snapshot_dir;
              subvolume = subvolume;
              target = target;
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
