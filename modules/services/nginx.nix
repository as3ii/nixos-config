{ config, lib, ... }:

let
  cfg = config.nginx;
in
{
  options.nginx = {
    enable = lib.mkEnableOption "Whether to enable nginx.";
    upstreams = lib.mkOption {
      type = lib.types.anything;
      description = ''
        Defines a group of servers to use as proxy target.
      '';
      default = { };
      example = {
        "backend" = {
          servers = {
            "backend1.example.com:8080" = {
              weight = 5;
            };
            "backend2.example.com" = {
              max_fails = 3;
              fail_timeout = "30s";
            };
            "backend3.example.com" = { };
            "backup1.example.com" = {
              backup = true;
            };
            "backup2.example.com" = {
              backup = true;
            };
          };
          extraConfig = ''
            keepalive 16;
          '';
        };
        "memcached" = {
          servers."unix:/run/memcached/memcached.sock" = { };
        };
      };
    };
    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = {
        localhost = { };
      };
      example = lib.literalExpression ''
        {
          "hydra.example.com" = {
            forceSSL = true;
            enableACME = true;
            locations."/" = {
              proxyPass = "http://localhost:3000";
            };
          };
        };
      '';
      description = "Declarative vhost config";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedTlsSettings = true;

      proxyTimeout = "20s"; # Default is 60s, set by recommendedProxySettings

      upstreams = cfg.upstreams;
      virtualHosts = cfg.virtualHosts;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.enable [ 80 443 ];
  };
}
