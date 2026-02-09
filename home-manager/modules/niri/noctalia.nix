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
        radiusRatio = 0.25;
        screenRadiusRatio = 0;
        dimmerOpacity = 0.5;
        lockOnSuspend = true;
        telemetryEnabled = false;
      };
      bar = {
        capsuleOpacity = 1;
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
            { id = "Network"; }
            { id = "Bluetooth"; }
            { id = "SystemMonitor"; showNetworkStats = true; compactMode = false; }
            { id = "Volume"; }
            { id = "Microphone"; }
            { id = "Brightness"; }
            { id = "Battery"; displayMode = "alwaysShow"; }
            { id = "NightLight"; }
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
              "Network"
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
            "brightness-card"
            #"weather-card"
            "media-sysmon-card"
          ];
        };

      dock.enabled = false;

      appLauncher.terminalCommand = "alacritty -e";

      location = {
        name = "Italy";
        firstDayOfWeek = 1;
      };

      wallpaper = {
        overviewEnabled = true;
        directory = "${config.xdg.userDirs.pictures}";
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
