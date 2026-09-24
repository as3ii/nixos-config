{ config, pkgs, ... }:

let
  # Sometimes I have the laptop lid closed and use only the external monitor,
  # but when it goes in power save (or wayidle do its job) the system thinks the
  # display is powered down or unplugged and systemd restart watching the lid switch.
  # This is not a fix, just a palliative
  noctalia-lid-switch-handler = pkgs.writeShellScriptBin "lid-toggle" ''
    # pidfile in XDG_RUNTIME_DIR, fallback to /tmp with UID
    if [ -n "''${XDG_RUNTIME_DIR:-}" ] && [ -d "''${XDG_RUNTIME_DIR:-}" ] && [ -w "''${XDG_RUNTIME_DIR:-}" ]; then
        pidfile="''${XDG_RUNTIME_DIR}/lid-switch-inhibit.pid"
    else
        _uid="$(id -u 2>/dev/null || echo 0)"
        pidfile="/tmp/lid-switch-inhibit-''${_uid}.pid"
    fi

    # Lid switch inhibited, kill process and remove pidfile
    if [ -f "$pidfile" ]; then
        # Check if file is not empty
        if [ -s "$pidfile" ]; then
            read -r pid < "$pidfile"
            # Check if the process actually exists
            if kill -0 "$pid" 2>/dev/null; then
                # Actually kill the process, then wait a bit
                kill "$pid" 2>/dev/null || true
                echo "Lid switch inhibition removed (PID $pid)"
                sleep 0.3
            fi
            # Verify the status
            if systemd-inhibit --who="lid-toggle" --list --no-legend 2>/dev/null | grep -q "$pid"; then
                echo "Warning: inhibitor still listed" >&2
            fi
            echo "Removing stale pidfile" >&2
            rm -f "$pidfile"
            ${pkgs.libnotify.out.outPath}/bin/notify-send -a "lid-toggle" "Lid switch inhibition removed"
            exit 0
        fi
        # Else: fallback to inhibit
    fi

    # Lid switch not inhibited
    # `tail -f /dev/null` is like an infinite sleep
    systemd-inhibit --what=handle-lid-switch --who=lid-toggle --why="Ignore lid switch" --mode=block tail -f /dev/null >/dev/null 2>&1 &
    pid=$!

    printf "%s\n" "$pid" > "$pidfile"
    chmod 600 "$pidfile"

    sleep 0.3
    if systemd-inhibit --who="lid-toggle" --list --no-legend 2>/dev/null | grep -q "$pid"; then
        echo "Lid switch inhibition active (PID $pid)"
        ${pkgs.libnotify.out.outPath}/bin/notify-send -a "lid-toggle" "Lid switch inhibition active"
    else
        # Cleanup on failure
        if ! kill -0 "$pid" 2>/dev/null; then
            echo "Error: failed to create inhibition" >&2
            rm -f "$pidfile"
            exit 1
        fi
    fi
  '';
in
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
            "inhibit-lidswitch"
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
        inhibit-lidswitch = {
          type = "custom_button";
          glyph = "device-desktop";
          actions.left = "exec ${noctalia-lid-switch-handler}/bin/lid-toggle";
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
