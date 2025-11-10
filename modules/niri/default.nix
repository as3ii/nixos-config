{ lib, pkgs, user, config, ... }:

let
  bt = config.hardware.bluetooth.enable;
  btpkgs = if bt then [ pkgs.bluez pkgs.blueman ] else [ ];
in
{
  # Enable niri
  programs.niri.enable = true;

  # Ensure basic services and features are present
  security.polkit.enable = true; # Polkit
  services.gnome.gnome-keyring.enable = false; # Secret service
  services.blueman.enable = true; # Bluetooth service
  security.pam.services = {
    # Use kwallet instead of gnome-keyring
    login.kwallet = lib.mkDefault {
      enable = true;
      package = pkgs.kdePackages.kwallet-pam;
    };
    swaylock = lib.mkDefault { }; # Lockscreen
  };

  home-manager.users.${user} = {
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        kdePackages.kwallet
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
      configPackages = [ pkgs.niri ];
      config.niri = {
        "org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
      };
    };

    systemd.user.services.niri-polkit = {
      Unit = {
        Description = "PolicyKit Authentication Agent for niri";
        WantedBy = [ "niri.service" ];
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    # Ensure basic programs are installed
    programs = {
      alacritty.enable = true; # Terminal
      fuzzel.enable = true; # App launcher
      # Lockscreen
      swaylock = {
        enable = true;
        settings = {
          image = "~/Pictures/fantasy-nature-river-mountains-lock.jpeg";
          ignore-empty-password = true;
          indicator-idle-visible = true;
          indicator-y-position = 900;
          inside-color = "00000000"; # Default to transparent
        };
      };
      waybar.enable = true; # Top bar
    };

    # Ensure basic services are enabled
    dbus.packages = [ pkgs.kdePackages.kwallet ];
    services = {
      mako.enable = true; # Notification daemon
      blueman-applet.enable = true;
      network-manager-applet.enable = true;
      # Idle management daemon
      swayidle = {
        enable = true;
        extraArgs = [ "-w" ];
        events = [
          { event = "before-sleep"; command = "swaylock -f"; }
        ];
        timeouts = [
          { timeout = 600; command = "niri msg action power-off-monitors"; resumeCommand = "niri msg action power-on-monitors"; }
        ];
      };
    };

    home.packages = with pkgs; [
      brightnessctl
      dconf
      networkmanagerapplet
      playerctl
      swaybg # wallpaper
      xwayland-satellite # xwayland support
    ] ++ btpkgs;

    xdg.configFile."niri/config.kdl".source = ./niri.kdl;

    xdg.configFile."waybar/config.jsonc".source = ./waybar.jsonc;
    xdg.configFile."waybar/style.css".source = ./waybar.css;
  };
}
