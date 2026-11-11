{ config, options, lib, pkgs, ... }:

let
  cfg = config.bind;
  useACME = cfg.doh.domain != null && lib.hasAttr cfg.doh.domain config.security.acme.certs;
  useCert = cfg.doh.cert-file != null && cfg.doh.key-file != null;
  blocklist-zone = lib.optionalString (cfg.blockListFile != null) (pkgs.runCommand "blocklist.zone"
    {
      nativeBuildInputs = with pkgs; [ coreutils ];
    } ''
    # Build the zone file header
    cat << EOF > $out
    \$TTL 1h
    @     IN    SOA     localhost.  root.localhost. (1 1h 15m 30d 2h)
    @     IN    NS      localhost.
    EOF
    # Blackhole the domains and all subdomains
    sed -n "h; s/$/ A 0.0.0.0/; p; g; s/^/*./; s/$/ A 0.0.0.0/; p" ${cfg.blockListFile} >> $out
  '');
in
{
  options.bind = {
    enable = lib.mkEnableOption "Whether to enable bind.";
    zones = options.services.bind.zones;
    doh = lib.mkOption {
      description = "DNS over HTTPS configuration.";
      default = { };
      example = lib.literalExpression ''
        {
          # With an ACME certificate externally configured
          enable = true;
          domain = "test.com";
          port = 8443;
          openPort = false;
        }
      '';
      type = lib.types.submodule ({
        options = {
          enable = lib.mkEnableOption "DNS over HTTPS";
          domain = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Domain to use for exposing DNS over HTTPS. If `null` an ephemeral
              certificate will be automatically created for the currently running
              instance. If a domain is specified and an ACME certificate is configured,
              it will be automatically used, `cert-file` and `key-file` otherwise.
            '';
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8443;
            description = "Port where to expose DNS over HTTPS.";
          };
          openPort = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to open the DoH port in the firewall.";
          };
          cert-file = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Certificate file.";
          };
          key-file = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Private key file.";
          };
        };
      });
    };
    cacheNetworks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        # Loopback
        "127.0.0.0/24"
        "::1/128"
        # LAN
        "192.168.0.0/16"
        "fd00::/8"
        # Tailscale
        "100.64.0.0/10"
        "fd7a:115c:a1e0::/48"
      ];
      description = ''
        What networks are allowed to use us as a resolver. Note that this is for recursive queries,
        all networks are allowed to query zones configured with the `zones` option by default.
      '';
    };
    forwarders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "9.9.9.9 tls quad9" # Main IPv4 + DoT
        "2620:fe::fe tls quad9" # Main IPv6 + DoT
        "149.112.112.112 tls quad9" # Secondary IPv4 + DoT
        "2620:fe::9 tls quad9" # Secondary IPv6 + DoT
      ];
      description = ''
        List of servers we should forward requests to. The presence of `".* tls quad9"`
        automatically adds `tls quad9 { ... };` to the config.
      '';
    };
    blockListFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/path/to/blockList";
      description = ''
        Path of the file containing the list of domains to block.
      '';
    };
    extraOptions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = lib.literalExpression ''
        # Setup DoT for quad9 resolver
        tls quad9 {
          remote-hostname "dns.quad9.net";
          session-tickets no;
        };
      '';
      description = ''
        Extra lines to be added to the options section of the generated named
        configuration file.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.doh.enable || (cfg.doh.cert-file == null) == (cfg.doh.key-file == null);
        message = ''
          `bind.doh.cert-file` and `bind.doh.key-file` must be set together,
          or both left null to use an ephemeral certificate.
        '';
      }
    ];

    services.bind = {
      enable = true;
      cacheNetworks = cfg.cacheNetworks;
      forward = "first"; # First try the forwarders, then fallback to recursive
      forwarders = cfg.forwarders;
      # https://bind9.readthedocs.io/en/latest/reference.html#options-block-definition-and-usage
      extraOptions = cfg.extraOptions
        + lib.optionalString cfg.doh.enable (if useACME || useCert then ''
        listen-on port ${toString cfg.doh.port} tls local-tls http default {any;};
        listen-on-v6 port ${toString cfg.doh.port} tls local-tls http default {any;};
      '' else ''
        listen-on port ${toString cfg.doh.port} tls ephemeral http default {any;};
        listen-on-v6 port ${toString cfg.doh.port} tls ephemeral http default {any;};
      '')
        + lib.optionalString (cfg.blockListFile != null) (
        ''
          # RPZ
          response-policy { zone "badlist"; };
        ''
      );
      # https://bind9.readthedocs.io/en/latest/reference.html#configuration-file-named-conf
      extraConfig = ''
      '' + lib.optionalString (lib.any (s: lib.hasSuffix "tls quad9" s) cfg.forwarders) ''
        # Setup DoT for quad9 resolver
        tls quad9 {
          # ca-file "${pkgs.cacert.out.outPath}/etc/ssl/certs/ca-bundle.crt";
          remote-hostname "dns.quad9.net";
          session-tickets no;
        };
      '' + lib.optionalString cfg.doh.enable (if useACME then ''
        tls local-tls {
          key-file "${config.security.acme.certs.${cfg.doh.domain}.directory}/key.pem";
          cert-file "${config.security.acme.certs.${cfg.doh.domain}.directory}/fullchain.pem";
        };
      '' else if useCert then ''
        tls local-tls {
          key-file "${cfg.doh.key-file}";
          cert-file "${cfg.doh.cert-file}";
        };
      '' else ""
      ) + lib.optionalString (cfg.blockListFile != null) ''
        zone "badlist" { type master; file "${blocklist-zone}"; allow-query { none; }; };
      '';
      # https://bind9.readthedocs.io/en/latest/reference.html#namedconf-statement-zone
      zones = cfg.zones;
    };
    # Open firewall ports
    networking.firewall = {
      allowedTCPPorts = [
        53
      ] ++ lib.optional (cfg.doh.enable && cfg.doh.openPort) cfg.doh.port;
      allowedUDPPorts = [ 53 ];
    };
  };
}
