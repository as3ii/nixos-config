{ lib, ... }:

{
  # Enable Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = lib.mkDefault true;
  };

  #services.blueman.enable = true;
}
