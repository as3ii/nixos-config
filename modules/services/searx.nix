{ config, lib, ... }:

let
  cfg = config.searx;
in
{
  # Docs: https://docs.searxng.org/admin/settings/index.html
  # Default config: https://github.com/searxng/searxng/blob/master/searx/settings.yml
  options.searx = {
    enable = lib.mkEnableOption "Whether to enable searx.";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "The TCP port to serve the searx service at.";
    };

    openFirewall = lib.mkEnableOption "Whether to open the port in the firewall.";

    botDetection = lib.mkEnableOption "Whether to enable bot detection. This will enable a local Redis server without persistence.";

    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing a random string used for cryptography purpose.
      the format should be `SEARX_SECRET_KEY=randomstring`";
    };

    trustedProxies = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "127.0.0.0/8"
        "::1"
      ];
      description = "Trusted proxies, required if bot detection is enabled.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.searx = {
      enable = true;
      environmentFile = cfg.secretKeyFile;
      limiterSettings = lib.mkIf cfg.botDetection {
        botdetection = {
          ipv4_prefix = 32;
          ipv6_prefix = 56;
          trusted_proxies = cfg.trustedProxies;
          ip_lists.block_ip = [ ]; # Block specified IPs
        };
      };
      redisCreateLocally = cfg.botDetection; # Required for limiter
      openFirewall = cfg.openFirewall;
      settings = {
        server = {
          port = cfg.port;
          bind_address = "[::]";
          secret_key = "$SEARX_SECRET_KEY";
        };
        use_default_settings.engines = {
          keep_only = [
            "duckduckgo"
            "arch linux wiki"
            "nixos wiki"
            "wikipedia"
          ];
        };
        search = {
          safe_search = 0; # 0 = none, 1 = moderate, 2 = strict
          default_lang = "en";
          languages = [
            "all"
            "en"
            "it"
          ];
        };
      };
    };
  };
}
