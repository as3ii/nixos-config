{ config, lib, options, ... }:

let
  cfg = config.cluster;
in
{
  imports = [
    ./services
    ./dns.nix
    ./network.nix
    ./authelia.nix
    ./nginx.nix
    ./tls.nix
  ];

  options.cluster = {
    domain = lib.mkOption {
      type = lib.types.str;
      description = "DNS zone of the cluster.";
      example = "homelab.lan";
    };
    adminEmail = lib.mkOption {
      type = lib.types.str;
      description = "SOA admin email";
      example = "admin@domain.com";
    };
    serial = lib.mkOption {
      type = lib.types.ints.u32;
      description = "SOA serial (eg. in YYYYMMDDNN format)";
      example = "2026013000";
    };
    ttl = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3600;
      description = "Default TTL for generated records.";
    };

    ipv4Network = lib.mkOption {
      type = lib.types.str;
      description = ''
        IPv4 network in CIDR notation (eg. `192.168.0.0/24`).
        (TODO) Used to automatically generate reverse DNS zone.
      '';
    };
    ipv6Network = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        IPv6 network in CIDR notation (eg. `fd00:cafe::/96`).
        (TODO) Used to automatically generate reverse DNS zone.
      '';
    };
    ipv4PrefixLength = lib.mkOption {
      type = lib.types.ints.between 8 32;
      default = lib.toInt (lib.last (lib.splitString "/" cfg.ipv4Network));
      description = "Prefix length applied to each node's ipv4 when configuring its interface.";
    };
    ipv6PrefixLength = lib.mkOption {
      type = lib.types.ints.between 8 128;
      default = if (cfg.ipv6Network != null) then lib.toInt (lib.last (lib.splitString "/" cfg.ipv6Network)) else 64;
      description = "Prefix length applied to each node's ipv6 when configuring its interface.";
    };
    ipv4Gateway = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Default IPv4 gateway for cluster members. `null` = do not set one.";
    };
    ipv6Gateway = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Default IPv6 gateway for cluster members. `null` = do not set one.";
    };

    nodes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            ipv4 = lib.mkOption {
              type = lib.types.str;
              description = "Static IPv4 address. Required.";
            };
            ipv6 = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Static ULA IPv6 (e.g. fd00::11). Null = SLAAC-only; AAAA is then skipped silently.";
            };
            interface = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                Network interface to configure with this node's inventory addresses.
                `null` = leave interface addressing to the host configuration.
              '';
            };
            dnsRole = lib.mkOption {
              type = lib.types.enum [
                "primary"
                "secondary"
                "none"
              ];
              default = "none";
              description = "bind role. Exactly one node in the cluster must be \"primary\".";
            };
            proxy = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether this node runs the cluster reverse proxy";
            };
          };
        }
      );
      example = lib.literalExpression ''
        {
          host-a = {
            ipv4 = "10.0.0.2";
            ipv6 = "fd00::2";
            dnsRole = "primary";
            proxy = true;
          };
          host-b = {
            ipv4 = "10.0.0.3";
            ipv6 = null; # Use only SLAAC
            dnsRole = "secondary";
            proxy = false;
          };
          host-c = {
            ipv4 = "10.0.0.4";
            ipv6 = "fd00::4";
            dnsRole = "none";
            proxy = true;
          };
        }
      '';
      description = "Cluster members keyed by NixOS `networking.hostName`.";
    };

    zoneFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = ''
        Cluster zones files. Files with `.zone` extension are treated as standard
        static zone files (see https://bind9.readthedocs.io/en/v9.21.26/chapter3.html#zone-file).
        Files with `.zone.nix` extension are evaluated and converted to a file using `dns.util.writezone`.
      '';
      example = lib.literalExpression ''
        [
          ./path/to/fully.qualified.domain.zone
          ./path/to/second-fully.qualified.domain.zone.nix
        ]
      '';
    };

    auth = {
      enable = lib.mkEnableOption "Enable Authelia.";
      node = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Cluster node that runs the Authelia instance.";
      };
      vhost = lib.mkOption {
        type = lib.types.str;
        default = "auth";
        description = "Host for the DNS record of the auth portal, used as <vhost>.<domain>";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 9091;
        description = "Internal TCP port listened by Authelia";
      };
      sopsSecretsFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to secrets yaml file. The file should have the following structure:
          ```
          authelia_jwt_secret: "secret"
          authelia_storage_encryption_key: "key"
          authelia_session_secret: "secret"
          ```
        '';
      };
      sopsUsersDBFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to users database yaml file. The file should have the following structure:
          ```
          users:
            username1:
              disabled: false
              displayname: "username1"
              password: "$argon2id$..." # generated with 'authelia crypto hash generate argon2'
              email: "username1@domain.com"
              groups:
                - "admins"
            username2:
              disabled: false
              displayname: "username2"
              password: "$argon2id$..."
              email: "username2@domain.com"
          ```
        '';
      };
    };

    tls = lib.mkOption {
      type = lib.types.submodule {
        options = {
          mode = lib.mkOption {
            type = lib.types.enum [ "disabled" "acme" "manual" ];
            default = "disabled";
            description = "Whether the TLS certificates are enabled and how are they handled";
          };
          certFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default =
              if cfg.nodes.${config.networking.hostName}.proxy then
                (
                  if cfg.tls.mode == "acme" then "${config.security.acme.certs.${cfg.domain}.directory}/fullchain.pem"
                  else if cfg.tls.mode == "manual" then cfg.tls.manual.certFile
                  else null
                ) else null;
            readOnly = true;
            description = "Fullchain PEM file, mode-independent";
          };
          keyFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default =
              if cfg.nodes.${config.networking.hostName}.proxy then
                (
                  if cfg.tls.mode == "acme" then "${config.security.acme.certs.${cfg.domain}.directory}/key.pem"
                  else if cfg.tls.mode == "manual" then cfg.tls.manual.keyFile
                  else null
                ) else null;
            readOnly = true;
            description = "Private key PEM file, mode-independent";
          };
          chainFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default =
              if cfg.nodes.${config.networking.hostName}.proxy && cfg.tls.mode == "manual"
              then cfg.tls.manual.chainFile
              else null;
            readOnly = true;
            description = "Optional chain PEM file, mode-independent";
          };

          reloadServices = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = ''
              List of service names to reload when the certificate is updated.
              For ACME, nginx is automatically added.
              For manually handled certificates, use sops reloadUnit, eg.
              `sops.secrets."tls-cert".reloadUnits = [ "nginx.service" ] ++ config.cluster.tls.reloadServices;`
            '';
          };

          acme = lib.mkOption {
            type = lib.types.submodule {
              options = {
                email = lib.mkOption {
                  type = lib.types.str;
                  default = cfg.adminEmail;
                  description = "Email address for account creation and correspondence from the CA";
                };
                server = lib.mkOption {
                  type = lib.types.enum [ "le-staging" "le-production" ];
                  default = "le-staging";
                  description = ''
                    Which LetsEncrypt API to use: staging or production.
                    While developing use the staging one to not reach certificate creation limits.
                  '';
                };
                keyType = lib.mkOption {
                  type = lib.types.enum [ "EC256" "EC384" "RSA2048" "RSA3072" "RSA4096" "RSA8192" ];
                  default = "EC384"; # Actual LE default is EC256, but we want higher security
                  description = "Which private key type to use";
                };
                profile = lib.mkOption {
                  type = lib.types.enum [ "classic" "tlsserver" "shortlived" ];
                  default = "tlsserver"; # Actual LE default is classic, but we want smaller certificates
                  description = "Which LetsEncrypt profile to use. See: https://letsencrypt.org/docs/profiles/";
                };
                dnsProvider = lib.mkOption {
                  type = lib.types.str;
                  example = "cloudflare";
                  description = ''
                    Which DNS provider to use for the DNS challenge.
                    See the "CLI flag name" field at https://go-acme.github.io/lego/dns/#dns-providers
                  '';
                };
                dnsResolver = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  example = "1.1.1.1:53";
                  description = ''
                    Set the resolver to use for performing recursive DNS queries.
                    Format: host:port. The default is to use the system resolvers.
                  '';
                };
                extraDomainNames = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ cfg.domain ];
                  description = "List of extra domain names, which are included in the one certificate to be issued.";
                };
                environmentFile = lib.mkOption {
                  type = lib.types.path;
                  description = ''
                    Path to the file containing the required secrets formatted as environment variables.
                    To see which variables you should set, see: https://go-acme.github.io/lego/dns/index.html
                  '';
                };
              };
            };
            default = { };
            example = lib.literalExpression ''
              {
                email = config.cluster.adminEmail;
                server = "le-production";
                dnsProvider = "cloudflare";
                dnsResolver = "1.1.1.1:53";
                environmentFile = config.sops.templates."cloudflare-dns".path;
              }
            '';
            description = "See https://go-acme.github.io/lego/references/ref-flags/index.html#options";
          };

          manual = lib.mkOption {
            type = lib.types.submodule {
              options = {
                certFile = lib.mkOption {
                  type = lib.types.path;
                  description = "Fullchain PEM file";
                };
                keyFile = lib.mkOption {
                  type = lib.types.path;
                  description = "Private key PEM file";
                };
                chainFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "Optional chain PEM file";
                };
              };
            };
            default = { };
            example = lib.literalExpression ''
              {
                certFile = /path/to/fullchain.pem;
                keyFile = /path/to/key.pem;
                chainFile = null;
              }
            '';
            description = ''
              Manually-handled certificate and key files. Set sops reloadUnit or
              some other mechanism to automatically reload nginx when certificates
              gets updated. Eg.
              `sops.secrets."tls-cert".reloadUnits = [ "nginx.service" ] ++ config.cluster.tls.reloadServices;`
            '';
          };
        };
      };
      example = lib.literalExpression ''
        {
          mode = "acme";
          reloadServices = [ "some-service.service" ];
          acme = {
            email = config.cluster.adminEmail;
            server = "le-production";
            dnsProvider = "cloudflare";
            dnsResolver = "1.1.1.1:53";
            environmentFile = config.sops.templates."cloudflare-dns".path;
          };
          # manual = {
          #   certFile = /path/to/fullchain.pem;
          #   keyFile = /path/to/key.pem;
          #   chainFile = null;
          # };
        }
      '';
      description = "TLS certificate management.";
    };

    landingPage = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Serve a landing page on proxy.<domain> and <proxyNode>.<domain>.";
          };
          file = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Custom HTML file. null = generated page listing proxied services.";
          };
          redirect = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "https://homepage.${cfg.domain}";
            description = "Redirect the landing vhosts instead of serving a page.";
          };
        };
      };
      default = { };
      description = "Cluster landing page shown on proxy and node hostnames.";
    };
  };

  config =
    let
      enableBind = builtins.length (builtins.attrNames (lib.filterAttrs (_: n: n.dnsRole == "none") cfg.nodes)) != builtins.length (builtins.attrNames cfg.nodes);
      ipv4s = map (n: n.ipv4) (builtins.attrValues cfg.nodes);
      ipv6s = lib.filter (v: v != null) (map (n: n.ipv6) (builtins.attrValues cfg.nodes));
      dnsNPrimaries = builtins.length (builtins.attrNames (lib.filterAttrs (_: n: n.dnsRole == "primary") cfg.nodes));
      dnsNSecondaries = builtins.length (builtins.attrNames (lib.filterAttrs (_: n: n.dnsRole == "secondary") cfg.nodes));

      nodeNames = builtins.attrNames cfg.nodes;
      enabledServices = lib.filterAttrs (_: s: s.nodes != [ ]) cfg.services;
      proxiedServices = lib.filterAttrs (_: s: s.expose == "proxy") enabledServices;
      proxiedServiceNames = builtins.attrNames (lib.mapAttrs (_: s: lib.flatten s.vhost) proxiedServices);
      proxyNames = builtins.attrNames (lib.filterAttrs (_: n: n.proxy) cfg.nodes);
      # Concatenate node names, nameserver aliases, and proxied service names
      aliases = [ "proxy" ]
        ++ lib.optional cfg.auth.enable cfg.auth.vhost
        ++ lib.optionals enableBind (map (i: "ns${toString i}") (lib.range 1 (1 + dnsNSecondaries)));
      nodeNameCollisions = builtins.filter (n: builtins.elem n aliases) nodeNames;
      vhostNames = lib.flatten (map (n: cfg.services.${n}.vhost) (builtins.attrNames enabledServices));
      serviceCollisions = builtins.filter (n: builtins.elem n (aliases ++ nodeNames)) vhostNames;
      missingServiceOptions =
        lib.concatMap
          (name:
            let
              serviceOpts = options.${name} or { };
              missing = lib.filter (opt: !(serviceOpts.${opt}.isDefined or true)) (builtins.attrNames serviceOpts);
            in
            lib.optional (cfg.services.${name}.nodes != [ ] && missing != [ ] && builtins.elem config.networking.hostName cfg.services.${name}.nodes) {
              inherit name missing;
            })
          (builtins.attrNames cfg.services);
    in
    {
      warnings = lib.optional
        (
          dnsNPrimaries == 1 && dnsNSecondaries == 0
        ) "cluster: no secondary DNS node defined.";

      assertions = [
        {
          assertion = dnsNPrimaries == 1 || (dnsNPrimaries == 0 && dnsNSecondaries == 0);
          message =
            if dnsNPrimaries > 1
            then "cluster: more then one node configured as primary DNS server."
            else if dnsNPrimaries == 0 && dnsNSecondaries > 0
            then "cluster: secondary DNS nodes defined without a primary one."
            else "cluster: invalid DNS roles configuration.";
        }
        {
          assertion = builtins.elem config.networking.hostName (builtins.attrNames cfg.nodes);
          message = "cluster: networking.hostName \"${config.networking.hostName}\" not found in cluster.nodes.";
        }
        {
          assertion = builtins.length (lib.unique ipv4s) == builtins.length ipv4s;
          message = "cluster: duplicate IPv4 address detected.";
        }
        {
          assertion = builtins.length (lib.unique ipv6s) == builtins.length ipv6s;
          message = "cluster: duplicate IPv6 address detected.";
        }
        {
          assertion = cfg.serial > 0 && cfg.serial < 4294967296; # serial must be between 0 and 2^32
          message = "cluster: DNS' serial must be between 1 and (2^32)-1 included.";
        }
        # TODO: validate ipv4Network, ipv6Network, ipv4Gateway, ipv6Gateway
        {
          assertion = cfg.ipv4Network != "";
          message = "cluster: IPv4 Network cannot be empty.";
        }
        {
          assertion = nodeNameCollisions == [ ];
          message = "cluster: node name(s) collide with reserved NS alias(es). Rename the node(s): ${lib.concatStringsSep ", " nodeNameCollisions}";
        }
        {
          assertion = serviceCollisions == [ ];
          message = "cluster: proxied service vhost(s) collide with node name(s). Rename the service vhost(s): ${lib.concatStringsSep ", " serviceCollisions}";
        }
        {
          assertion = lib.all (s: lib.all (b: builtins.elem b nodeNames) s.nodes) (builtins.attrValues cfg.services);
          message = "cluster: service backend references unknown node(s).";
        }
        {
          assertion = !(cfg.auth.enable && proxyNames == [ ]);
          message = "cluster: authentication service needs a proxy.";
        }
        {
          assertion = !(proxiedServiceNames != [ ] && proxyNames == [ ]);
          message = "cluster: service(es) use expose=\"proxy\" but no node has proxy enabled.";
        }
        {
          assertion = !cfg.auth.enable || (cfg.auth.node != "" && builtins.elem cfg.auth.node nodeNames);
          message = "cluster: authentication service enabled with invalid node.";
        }
        {
          assertion = builtins.length (lib.unique vhostNames) == builtins.length vhostNames;
          message = "cluster: duplicate service vhost label(s).";
        }
        {
          assertion = lib.all (n: cfg.services.${n}.vhost != [ ]) (builtins.attrNames cfg.services);
          message = "cluster: service(s) with an empty vhost list.";
        }
        {
          assertion = lib.all (v: v != "") vhostNames;
          message = "cluster: service vhost labels must not be empty strings.";
        }
        {
          assertion = missingServiceOptions == [ ];
          message = ''
            cluster: enabled service(s) have required options with no value:
            ${lib.concatMapStrings
                (s: "  - " + lib.concatMapStringsSep ", " (o: "cluster.services.${s.name}.otherOptions.${o}") s.missing + "\n")
                missingServiceOptions}
            Set them in the inventory that defines `cluster.services`.
          '';
        }
        {
          assertion = cfg.tls.mode != "manual" || cfg.tls.manual.certFile != cfg.tls.manual.keyFile;
          message = "cluster: tls manual.certFile and manual.keyFile must be different.";
        }
        {
          assertion = cfg.tls.mode != "acme" || lib.elem cfg.domain cfg.tls.acme.extraDomainNames;
          message = "cluster: tls.acme.extraDomainNames must include cluster.domain (the apex).";
        }
        {
          assertion = cfg.tls.mode != "acme" || builtins.length (lib.unique cfg.tls.acme.extraDomainNames) == builtins.length cfg.tls.acme.extraDomainNames;
          message = "cluster: tls.acme.extraDomainNames must not contain duplicates.";
        }
        {
          assertion = lib.all (s: s != "") cfg.tls.reloadServices;
          message = "cluster: tls.reloadServices must not contain empty service names.";
        }
        {
          assertion = builtins.length (lib.unique cfg.tls.reloadServices) == builtins.length cfg.tls.reloadServices;
          message = "cluster.tls: reloadServices must not contain duplicates.";
        }
        {
          assertion = (cfg.tls.certFile == null) == (cfg.tls.keyFile == null);
          message = "cluster: tls internal invariant violated: certFile/keyFile mismatch.";
        }
        {
          assertion = (cfg.landingPage.file == null || cfg.landingPage.redirect == null);
          message = "cluster: only one between `landingPage.file` and `landingPage.redirect` can be set at the same time.";
        }
      ];

      # Set it in _module.args to make it available during option parsing
      _module.args.mkClusterServiceOption = name: lib.mkOption {
        type = lib.types.submodule {
          options = {
            nodes = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Cluster nodes that runs this service (DNS round-robin).";
            };
            port = lib.mkOption {
              type = lib.types.port;
              description = "Internal TCP port listened by this service";
            };
            scheme = lib.mkOption {
              type = lib.types.enum [ "http" "https" ];
              default = "http";
              description = "Scheme used to reach the service.";
            };
            expose = lib.mkOption {
              type = lib.types.enum [ "proxy" "direct" ];
              default = "proxy";
              description = ''
                "proxy": reachable via the reverse proxy at <vhost>.<domain>.
                "direct": reachable directly via <vhost>.<node>.<domain>.
              '';
            };
            auth = lib.mkOption {
              type = lib.types.enum [ "none" "one_factor" "two_factor" ];
              default = "none";
              description = "Require authentication to access this service.";
            };
            vhost = lib.mkOption {
              type = with lib.types; either str (listOf str);
              default = name;
              apply = v: if builtins.isList v then v else [ v ];
              description = "Host(s) for the DNS record for the proxied vhost. Defaults to the attr key.";
            };
            otherOptions = lib.mkOption {
              type = lib.types.submodule {
                # Allow setting only non-read-only options, and exclude "enable" and "port"
                options = removeAttrs (lib.filterAttrs (_: opt: !(opt.readOnly or false)) (options.${name} or { })) [ "enable" "port" ];
              };
              default = { };
              description = "Other service-specific options";
            };
          };
        };
        default = { };
      };
    };
}
