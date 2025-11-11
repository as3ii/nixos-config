{ pkgs, user, ... }:

{
  # Enable niri
  programs.niri.enable = true;

  # Ensure basic services and features are present
  security.polkit.enable = true; # Polkit
  services.gnome.gnome-keyring.enable = true; # Secret service

  home-manager.users.${user} = {
    imports = [ ./noctalia.nix ];

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
      configPackages = [ pkgs.niri ];
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
      # Idle management daemon
      # swayidle = {
      #   enable = true;
      #   extraArgs = [ "-w" ];
      #   events = [
      #     { event = "before-sleep"; command = "swaylock -f"; }
      #   ];
      #   timeouts = [
      #     { timeout = 600; command = "niri msg action power-off-monitors"; resumeCommand = "niri msg action power-on-monitors"; }
      #   ];
      # };
    };

    home.packages = with pkgs; [
      brightnessctl
      networkmanagerapplet
      playerctl
      xwayland-satellite # xwayland support
    ];

    xdg.configFile."niri/config.kdl".source = ./niri.kdl;

    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style.name = "breeze";
    };
  };
}
