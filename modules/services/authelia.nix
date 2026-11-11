{ config, lib, ... }:

let
  cfg = config.authelia;
in
{
  options.authelia = {
    enable = lib.mkEnableOption "Whether to enable Authelia.";
    port = lib.mkOption {
      type = lib.types.port;
      default = 9091;
      description = "Internal TCP port listened by this service";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain used for cookies, as issuer for TOTP and shown when using Webauthn";
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/authelia-main";
      readOnly = true;
      description = "Path where the sqlite DB will be stored. Use this value only for documentation or impermanence/preservation.";
    };
    usersDB = lib.mkOption {
      type = lib.types.path;
      description = "Path to the yaml/toml/json file with the users details list";
    };
    ACLs = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            example = "test.domain.com";
            description = "The domain name to match, optionally it can be a wildcard like `*.test.domain.com`.";
          };
          policy = lib.mkOption {
            type = lib.types.enum [ "deny" "bypass" "one_factor" "two_factor" ];
            default = "one_factor";
            description = ''
              The policy applied to the request that matches the domain.
              See https://www.authelia.com/configuration/security/access-control/#policies
            '';
          };
          subject = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf (lib.types.listOf lib.types.str));
            default = null;
            example = lib.literalExpression ''
              # user foo OR (users that are in both admin AND app-name groups)
              # OR users in the superadmin group
              [
                [ "user:foo" ]
                [ "group:admin" "group:app-name" ]
                [ "group:superadmin" ]
              ]
            '';
            description = ''
              Match users, groups and/or OAuth clients. The first level of the list
              uses `OR` logic, the second level uses `AND` logic. When set, only
              "one_factor" or "two_factor" policies are allowed.
            '';
          };
          methods = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf (lib.types.enum [ "GET" "HEAD" "POST" "PUT" "DELETE" "CONNECT" "OPTIONS" "TRACE" ]));
            default = null;
            example = lib.literalExpression ''[ "GET" "POST" ]'';
            description = ''
              Match the HTTP request method. See the official documentation for more information
              https://www.authelia.com/configuration/security/access-control/#methods
            '';
          };
          networks = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            example = lib.literalExpression ''[ "10.0.0.0/8" "192.168.0.0/16" ]'';
            description = ''
              Match the source IP address, read from the `X-Forwarded-For` header.
              The use CIDR notation is mandatory.
            '';
          };
          resources = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            example = lib.literalExpression ''[ "^/api([/?].*)?$" ]'';
            description = "Match the path and query of the request using regex.";
          };
        };
      });
      description = "Access Control rules.";
    };
    secrets = lib.mkOption {
      type = lib.types.submodule {
        options = {
          jwtSecretFile = lib.mkOption {
            type = lib.types.externalPath;
            description = "File containing the key for signing of JSON Web Token";
          };
          sessionSecretFile = lib.mkOption {
            type = lib.types.externalPath;
            description = "File containing the secret for encrypting session storage (cookie or redis)";
          };
          storageEncryptionKeyFile = lib.mkOption {
            type = lib.types.externalPath;
            description = "File containing the key for encrypting storage DB";
          };
        };
      };
    };
    metrics = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable telemetry/metrics. If enabled, it will be reachable on port 9959
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # See: https://github.com/authelia/authelia/blob/v4.39.28/config.template.yml
    # See: https://www.authelia.com/configuration/
    services.authelia.instances.main = {
      enable = true;

      secrets = {
        jwtSecretFile = cfg.secrets.jwtSecretFile;
        sessionSecretFile = cfg.secrets.sessionSecretFile;
        storageEncryptionKeyFile = cfg.secrets.storageEncryptionKeyFile;
      };

      settings = {
        theme = "auto";
        log.level = "info";
        default_2fa_method = "webauthn"; # totp, webauthn, mobile_push
        server.address = "tcp://:${toString cfg.port}/";
        # tls = {
        #   key = "path";
        #   certificate = "path";
        # };

        # First factor
        authentication_backend.file.path = cfg.usersDB;

        # Second factors
        totp = {
          issuer = cfg.domain;
          allowed_algorithms = [ "sha1" "sha256" ];
          allowed_digits = [ 6 8 ];
          apps = {
            apple_store.disable = true;
            google_play.disable = true;
            aegis = {
              disable = false;
              url = "https://getaegis.app/";
            };
          };
        };
        webauthn = {
          display_name = cfg.domain;
        };
        duo_api.disable = true;

        # ACLs
        access_control = {
          default_policy = "deny";
          rules = cfg.ACLs;
        };

        # Anti-spam
        regulation = {
          modes = [ "user" "ip" ];
          max_retries = 3;
          find_time = "3m";
          ban_time = "5m";
        };

        # Passwords rules
        password_policy = {
          standard = {
            enabled = false;
            min_length = 8;
            max_length = 0;
            require_uppercase = true;
            require_lowercase = true;
            require_number = true;
            require_special = true;
          };
          zxcvbn = {
            enabled = true;
            min_score = 4; # 3 = more then 10^8 guesses, 4 = more then 10^10 guesses
          };
        };

        session.cookies = {
          domain = cfg.domain;
        };

        storage.local.path = "${cfg.dataDir}/db.sqlite3";

        # TODO: implement smtp notifications
        notifier.filesystem.filename = "${cfg.dataDir}/notification.txt";
        notifier.smtp = lib.mkIf false {
          address = "";
          timeout = "5s";
          username = "";
          password = "";
          sender = "\"Authelia\" <noreply@${cfg.domain}>";
          identifier = config.networking.hostName + ".${cfg.domain}";
          subject = "[Authelia] {title}";
        };

        telemetry.metrics = {
          enabled = cfg.metrics;
          address = "tcp://:9959/";
        };
      };
    };
  };
}
