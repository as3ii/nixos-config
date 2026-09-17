{ config, ... }:

{
  programs.noctalia = {
    enable = true;
    # https://docs.noctalia.dev/noctalia/configuration/
    settings = {
      shell = {
        corner_radius_scale = 0.25;
        animation.speed = 1.5;
        panel.shadow = false;
        time_format = "{:%H:%M}";
        date_format = "{:%Y-%m-%d}";
        telemetry_enabled = false;
      };
      bar = {
        order = [ "main" ];
        default = {
          radius = 0;
          scale = 1.1;
          margin_ends = 0;
          padding = 0;
          capsule = true;
          capsule_thickness = 0.8;
          capsule_padding = 4;

          capsule_group = [
            {
              id = "sysmon";
              members = [
                "sysmon"
                "sysmon-temp"
                "sysmon-ram"
                "sysmon-disk"
              ];
            }
          ];

          start = [
            "control-center"
            "workspaces"
            "active_window"
          ];
          center = [
            "clock"
            "noctalia/timer:bar"
          ];
          end = [
            "network"
            "bluetooth"
            "group:sysmon"
            "volume"
            "input-volume"
            "privacy"
            "brightness"
            "battery"
            "nightlight"
            "notifications"
            "caffeine"
            "power_profile"
            "tray"
            "session"
          ];
        };
      };

      widget = {
        active_window = {
          max_length = 500;
          title_scroll = "on_hover";
        };
        clock.format = "{:%H:%M %a, %b %d}";
        network.show_label = false;
        tray.drawer = true;
        power_profile.actions = {
          scroll_up = "none";
          scroll_down = "none";
        };
        # Custom widgets
        input-volume = {
          type = "volume";
          device = "input";
        };
        sysmon-temp = {
          type = "sysmon";
          stat = "cpu_temp";
        };
        sysmon-ram = {
          type = "sysmon";
          stat = "ram_used";
        };
        sysmon-disk = {
          type = "sysmon";
          stat = "disk_used_pct";
        };
      };

      dock.enabled = false;

      desktop_widgets.enabled = false;

      wallpaper.directory = "${config.xdg.userDirs.pictures}";
      backdrop.enabled = true;

      theme = {
        mode = "dark";
        templates.enable_community_templates = false;
      };

      location = {
        auto_locate = false;
        address = "Italy";
        # custom_schedule = true;
        # sunrise = "07:00";
        # sunset = "20:00";
      };

      nightlight = {
        enabled = true;
        temperature_night = "4500";
        temperature_day = "6500";
      };

      plugins = {
        enabled = [
          "noctalia/timer"
        ];
        auto_update = "official";
      };
    };
  };

  services.swayidle.events."before-sleep" = "noctalia msg session lock";
}
