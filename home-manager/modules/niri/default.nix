{ pkgs, ... }:

{
  imports = [ ./noctalia.nix ];

  wayland.systemd.target = "niri.service";

  # Ensure basic programs are installed
  programs = {
    alacritty.enable = true; # Terminal
    # App launcher
    fuzzel = {
      enable = true;
      settings = {
        colors = {
          background = "070722ff";
          text = "ffffffff";
          prompt = "a9aefeff";
          placeholder = "9bfeceff";
          input = "fff59bff";
          match = "9bfeceff";
          selection = "fff59bff";
          selection-text = "a9aefeff";
          selection-match = "000000ff";
          counter = "a9eafeff";
          border = "fff59bff";
        };
      };
    };
  };

  # Ensure basic services are enabled
  services = {
    network-manager-applet.enable = true; # Keeping it because noctalia don't handle 802.1X/WPA2 Enterprise
    # Clipboard history
    cliphist = {
      enable = true;
      allowImages = true;
    };
    # Idle management daemon
    swayidle = {
      enable = true;
      extraArgs = [ "-w" ];
      events = {
        # "before-sleep" = "${pkgs.swaylock}/bin/swaylock -f";
      };
      timeouts = [
        # 5 minutes
        { timeout = 300; command = "niri msg action power-off-monitors"; resumeCommand = "niri msg action power-on-monitors"; }
      ];
    };
  };

  home.packages = with pkgs; [
    brightnessctl
    networkmanagerapplet
    playerctl
    oculante # Image viewer
  ] ++ (with pkgs.kdePackages; [
    ark # GUI archive manager
    dolphin # GUI file manager
    dolphin-plugins
    discover # GUI flatpak handling
  ]);

  xdg.configFile."niri/config.kdl".source = ./niri.kdl;

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "breeze";
  };
  gtk = {
    enable = true;
    theme = {
      package = pkgs.gnome-themes-extra;
      name = "Adwaita-dark";
    };
  };
}
