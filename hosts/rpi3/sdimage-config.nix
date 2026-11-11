{ lib, pkgs, ... }:

{
  sdImage = {
    compressImage = false;
    nixPathRegistrationFile = "/persistent/nix-path-registration";
    firmwareSize = 100; # In MB, default = 30, increased to allow firmware updates
    expandOnBoot = true;
  };
  # Override default script, to point to /persistent instead of /
  systemd.services.expand-root-partition.script = lib.mkForce ''
    # Figure out device names for the boot device and root filesystem.
    rootPart=$(${lib.getExe' pkgs.util-linux "findmnt"} -n -o SOURCE /persistent)
    bootDevice=$(${lib.getExe' pkgs.util-linux "lsblk"} -npo PKNAME $rootPart)
    partNum=$(${lib.getExe' pkgs.util-linux "lsblk"} -npo MAJ:MIN $rootPart | ${lib.getExe pkgs.gawk} -F: '{print $2}')

    # Resize the root partition and the filesystem to fit the disk
    echo ",+," | ${lib.getExe' pkgs.util-linux "sfdisk"} -N$partNum --no-reread $bootDevice
    ${lib.getExe' pkgs.parted "partprobe"}
    ${lib.getExe' pkgs.e2fsprogs "resize2fs"} $rootPart
  '';
}
