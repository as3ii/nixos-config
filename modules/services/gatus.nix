{ lib, config, pkgs, ... }:

let
  cfg = config.gatus;
in
{
  options.gatus = {
    enable = lib.mkEnableOption "Whether to enable Gatus.";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "The TCP port to serve the Gatus service at.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        File to load as environment file. Environmental variables from this file
        can be interpolated in the configuration file using `$\{VARIABLE}`.
        This is useful to avoid putting secrets into the nix store.
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/gatus";
      readOnly = true;
      description = "Path where the sqlite DB will be stored. Use this value only for documentation or impermanence/preservation.";
    };

    preservationDirs = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [
        {
          directory = "/var/lib/private/gatus";
          user = "nobody";
          group = "nogroup";
          mode = "0700";
          configureParent = true;
          parent = {
            user = "root";
            group = "root";
            mode = "0700";
          };
        }
      ];
      readOnly = true;
      description = "Preservation entries for Gatus' systemd StateDirectory.";
    };

    endpoints = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        freeformType = (pkgs.formats.yaml { }).type;
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            example = "website";
            description = "The name of the endpoint.";
          };
          group = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "My Group";
            description = "The group of the endpoint for organization";
          };
          url = lib.mkOption {
            type = lib.types.str;
            example = "https://example.com";
            description = ''
              The target URL to monitor (not used for EXTERNAL endpoints).
              Allowed protocols: http, https, icmp, tcp, udp, tls, starttls, ssh,
              grpc, wss (websocket)
            '';
          };
          interval = lib.mkOption {
            type = lib.types.str;
            example = "30s";
            description = "Duration between each endpoint health evaluation (30s to 1h)";
          };
          conditions = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = lib.literalExpression ''
              [
                "[STATUS] < 300"
                "[BODY].user.name == john"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ]
            '';
            description = ''
              Requirements that must be met for an endpoint to be considered healthy.
              See https://github.com/TwiN/gatus#conditions.
            '';
          };
          alerts = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                type = lib.mkOption {
                  type = lib.types.str;
                  example = "discord";
                  description = "The alerting provider. See https://github.com/TwiN/gatus#alerting";
                };
                failure-threshold = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 1;
                  description = "Number of times in a row that the health check of an endpoint must fail before an alert is considered triggered";
                };
                success-threshold = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 1;
                  description = "Number of times in a row that the health check of an endpoint must be successful after an alert in a triggered state is considered resolved";
                };
                send-on-resolved = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Whether to send a communication to the provider when the alert has been resolved";
                };
              };
            });
            default = [ ];
            example = lib.literalExpression ''
              [
                {
                  type = "slack";
                  failure-threshold = 2;
                  success-threshold = 3;
                  send-on-resolved = true;
                }
              ]
            '';
          };
        };
      });
      description = "For more information see https://github.com/TwiN/gatus#endpoints.";
    };

    alerting = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = { };
      example = lib.literalExpression ''
        {
          email = {
            to = "test@example.org";
            from = "gatus@example.org";
            username = "username";
            password = "$\{PASSWORD}"; # Read from environmentFile
            host = "smtp.test.com";
            port = 587;
            default-alert = {
              failure-threshold = 2;
              success-threshold = 2;
              send-on-resolved = true;
            };
          };
        }
      '';
      description = "Setup alerts. See https://github.com/TwiN/gatus#alerting";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for the Gatus web interface.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.gatus = {
      enable = true;
      settings = {
        web = {
          port = cfg.port;
          read-buffer-size = 32768; # Fixes error: 431 Request Header Fields Too Large
        };
        endpoints = cfg.endpoints;
        alerting = cfg.alerting;
        storage = {
          type = "sqlite";
          path = "${cfg.dataDir}/data.db";
        };
        ui.default-sort-by = "group";
        #metrics = true;
      };
      environmentFile = cfg.environmentFile;
      openFirewall = cfg.openFirewall;
    };
  };
}
