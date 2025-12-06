{ config, noctalia, ... }:

{
  imports = [ noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
    # https://docs.noctalia.dev/getting-started/nixos/#config-ref
    settings = {
      general = {
        animationSpeed = 1.5;
        enableShadows = false;
        radiusRatio = 0;
        screenRadiusRatio = 0;
      };
      bar = {
        widgets = {
          left = [
            { id = "ControlCenter"; useDistroLogo = true; }
            { id = "Workspace"; }
            { id = "ActiveWindow"; maxWidth = 500; }
          ];
          center = [
            { id = "Clock"; formatHorizontal = "HH:mm ddd, MMM dd"; }
          ];
          right = [
            { id = "WiFi"; }
            { id = "Bluetooth"; }
            { id = "SystemMonitor"; showNetworkStats = true; }
            { id = "Volume"; }
            { id = "Microphone"; }
            { id = "Brightness"; }
            { id = "Battery"; displayMode = "alwaysShow"; }
            { id = "NotificationHistory"; }
            { id = "KeepAwake"; }
            { id = "PowerProfile"; }
            { id = "Tray"; }
            { id = "SessionMenu"; }
          ];
        };
      };
      controlCenter =
        let
          ids = map (id: { inherit id; });
          idc = map (id: { inherit id; enabled = true; });
        in
        {
          shortcuts = {
            left = ids [
              "WiFi"
              "Bluetooth"
            ];
            right = ids [
              "Notifications"
              "PowerProfile"
              "KeepAwake"
              "NightLight"
            ];
          };
          cards = idc [
            "profile-card"
            "shortcuts-card"
            "audio-card"
            #"weather-card"
            "media-sysmon-card"
          ];
        };

      dock.enabled = false;

      location = {
        name = "Italy";
        firstDayOfWeek = 1;
      };

      wallpaper = {
        overviewEnabled = true;
        defaultWallpaper = "${config.xdg.userDirs.pictures}/fantasy-nature-river-mountains.jpeg";
      };

      nightLight = {
        enabled = true;
        nightTemp = 4500;
        dayTemp = 6500;
        autoSchedule = false;
        manualSunrise = "07:00";
        manualSunset = "20:00";
      };
    };
  };

  services.swayidle.events."before-sleep" = "noctalia-shell ipc call lockScreen lock";
}
