{ pkgs, ... }:

{
  # Enable sddm
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    autoNumlock = true;
    enableHidpi = true;
  };

  # Enable plasma6
  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = with pkgs; [
    kdePackages.plasma-thunderbolt
    kdePackages.discover
    kdePackages.kgpg
  ];

  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.elisa
    kdePackages.oxygen
    kdePackages.kate
  ];
}
