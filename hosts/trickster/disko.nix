{ config, lib, ... }:

{
  fileSystems."/nix".neededForBoot = true;

  disko.devices.disk.main = {
    imageName = "nixos-${config.networking.hostName}";
    device = "/dev/disk/by-id/ata-FPT310M4SSD256G_FD2561233N00034";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00"; # EFI partition
          priority = 1;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ]; # Override existing partition
            subvolumes = {
              "/snapshot" = {
                mountpoint = "/snapshot";
                mountOptions = [ "subvol=snapshot" "noatime" "compress=zstd:2" "discard=async" ];
              };
              "/swap" = {
                mountpoint = "/swap";
                mountOptions = [ "subvol=swap" "noatime" "discard=async" ];
                swap.swapfile.size = "8G";
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [ "subvol=nix" "noatime" "compress=zstd:2" "discard=async" ];
              };
            };
          };
        };
      };
    };
  };

  # If preservation is NOT used setup 2 normal subvolumes for root and home
  disko.devices.disk.main.content.partitions.root.content.subvolumes."/" = lib.mkIf (config.preservation.enable == false) {
    mountpoint = "/";
    mountOptions = [ "subvol=root" "noatime" "discard=async" ];
  };
  disko.devices.disk.main.content.partitions.root.content.subvolumes."/home" = lib.mkIf (config.preservation.enable == false) {
    mountpoint = "/home";
    mountOptions = [ "subvol=home" "noatime" "discard=async" ];
  };

  # If preservation is used setup a persistent subvolume and mount root in tmpfs
  disko.devices.nodev = lib.mkIf config.preservation.enable {
    "/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=25%"
        "mode=755"
      ];
    };
  };
  disko.devices.disk.main.content.partitions.root.content.subvolumes."/persistent" = lib.mkIf config.preservation.enable {
    mountpoint = "/persistent";
    mountOptions = [ "subvol=persistent" "noatime" "compress=zstd:2" "discard=async" ];
  };
}
