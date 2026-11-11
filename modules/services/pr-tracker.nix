{ lib, config, pkgs, ... }:

let
  cfg = config.pr-tracker;
  pr-tracker-sync = pkgs.writeShellScript "pr-tracker-sync.sh" ''
    for branch in nixpkgs-unstable nixos-unstable-small nixos-unstable master; do
        ${pkgs.git} -C "${cfg.dataDir}/nixpkgs" switch "$branch"
        ${pkgs.git} -C "${cfg.dataDir}/nixpkgs" pull
    done
  '';
  pr-tracker-init = pkgs.writeShellScript "pr-tracker-init.sh" ''
    if [ ! -d "${cfg.dataDir}/nixpkgs" ] || [ ! -d "${cfg.dataDir}/nixpkgs/.git" ]; then
        ${pkgs.git} clone https://github.com/NixOS/nixpkgs "${cfg.dataDir}/nixpkgs"
        ${pr-tracker-sync}
    fi
  '';
in
{
  options.pr-tracker = {
    enable = lib.mkEnableOption "Enable pr-tracker, a web interface for nixpkgs PR tracking.";

    package = lib.mkPackageOption pkgs "pr-tracker" { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "The TCP port to serve the pr-tracker service at.";
    };

    githubTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing the github API token";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/pr-tracker";
      description = "Path where a copy of the nixpkgs git repository will be stored";
    };

    refreshInterval = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "3h";
      description = ''
        How often the git repository should be synced. See {manpage}`systemd.time(7)`
        for more information about the format. Setting it to null disables the timer,
        requiring starting the sync job manually.
      '';
    };

    userAgent = lib.mkOption {
      type = lib.types.str;
      example = "pr-tracker (your name)";
      description = "User agent used to call github APIs";
    };

    sourceUrl = lib.mkOption {
      type = lib.types.str;
      default = cfg.package.src.url;
      example = "https://git.qyliss.net/pr-tracker";
      description = "Link to pr-tracker sources";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.userAgent != "";
        message = "User Agent cannot be empty";
      }
    ];

    users.users.pr-tracker = {
      group = "pr-tracker";
      home = cfg.dataDir;
      createHome = true;
      isSystemUser = true;
    };
    users.groups.pr-tracker = { };

    systemd = {
      sockets.pr-tracker = {
        description = "pr-tracker socket";
        wantedBy = [ "sockets.target" ];
        socketConfig = {
          ListenStream = cfg.port;
          TriggerLimitIntervalSec = 0;
        };
      };

      services = {
        pr-tracker = {
          description = "Web interface for nixpkgs PR tracking";
          after = [ "network.target" ];
          serviceConfig = {
            User = "pr-tracker";
            Group = "pr-tracker";
            Type = "simple";
            Restart = "on-failure";
            ExecStartPre = pr-tracker-init;
            ExecStart = "${lib.getExe cfg.package} --path '${cfg.dataDir}/nixpkgs' --remote origin --user-agent '${cfg.userAgent}' --source-url '${cfg.sourceUrl}' < '${cfg.githubTokenFile}'";
            WorkingDirectory = cfg.dataDir;
            ReadWritePaths = [
              cfg.dataDir
            ];
            ProtectSystem = "strict";
            NoNewPrivileges = true;
            PrivateDevices = true;
            PrivateTmp = true;
            ProtectHome = true;
          };
        };
        pr-tracker-git = {
          description = "Sync service for nixpkgs git instance for pr-tracker";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            User = "pr-tracker";
            Group = "pr-tracker";
            Type = "oneshot";
            ExecStart = pr-tracker-sync;
            WorkingDirectory = cfg.dataDir;
            ReadWritePaths = [
              cfg.dataDir
            ];
            ProtectSystem = "strict";
            NoNewPrivileges = true;
            PrivateDevices = true;
            PrivateTmp = true;
            ProtectHome = true;
          };
        };
      };

      timers.pr-tracker-git = lib.mkIf (cfg.refreshInterval != null) {
        description = "Timer to sync nixpkgs git repository";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.refreshInterval;
          AccuracySec = "10min";
          persistent = true;
        };
      };
    };
  };
}
