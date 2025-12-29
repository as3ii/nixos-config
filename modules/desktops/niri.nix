{ pkgs, ... }:

{
  # Enable sddm
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    autoNumlock = true;
    enableHidpi = true;
    theme = "sddm-astronaut-theme";
  };

  # Enable niri
  programs.niri = {
    enable = true;
    useNautilus = false;
  };

  # Ensure basic services and features are present
  security.polkit.enable = true; # Polkit
  services.gnome.gnome-keyring.enable = true; # Secret service
  programs.seahorse.enable = true; # Keys/password management GUI

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    (sddm-astronaut.override { embeddedTheme = "puple_leaves"; })
  ];

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      gnome-keyring
    ];
    config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
  };
}
