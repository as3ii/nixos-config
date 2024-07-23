{ lib, ... }:

{
  # Enable Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = lib.mkDefault false;
  };

  #services.blueman.enable = true;
}

# vim: sw=2
