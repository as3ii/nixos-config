{ config, lib, ... }:

let
  cfg = config.cluster;
in
{
  imports = [ ../../modules/cluster ];

  cluster = {
    # This is an inventory file, must be handled carefully and kept updated

    # DNS stuff
    domain = "tn.lorenzodebe.com";
    adminEmail = "web@lorenzodebe.com";
    serial = 2026111000; # YYYYMMDDNN, date + counter
    ttl = 3600;
    zoneFiles = [
      ./tn.lorenzodebe.com.zone.nix
      ./88.168.192.in-addr.arpa.zone.nix # 192.168.88/24
    ];

    ipv4Network = "192.168.88.0/24";
    ipv6Network = "fd88::/64";
    ipv4Gateway = "192.168.88.1";
    ipv6Gateway = "fd88::1";

    nodes = {
      trickster = {
        ipv4 = "192.168.88.2";
        ipv6 = "fd88::2";
        interface = "bond0";
        dnsRole = "primary";
        proxy = true;
      };
      rpi3 = {
        ipv4 = "192.168.88.3";
        ipv6 = "fd88::3";
        interface = "enxb827eba700b8";
        dnsRole = "secondary";
        proxy = true;
      };
    };

    auth = {
      enable = true;
      node = "trickster";
      vhost = "auth";
      port = 9091;
      sopsSecretsFile = ../../secrets/homelab/authelia.yaml;
      sopsUsersDBFile = ../../secrets/homelab/authelia-users.yaml.enc;
    };

    services = {
      gatus = {
        nodes = [ "rpi3" ];
        port = 8080;
        scheme = "http";
        expose = "proxy";
        auth = "none";
        otherOptions = {
          openFirewall = true;
          endpoints =
            # ICMP nodes
            (lib.concatMap
              (node: [
                {
                  name = "IPv4 ${node}";
                  group = "Nodes";
                  interval = "30s";
                  url = "icmp://${cfg.nodes.${node}.ipv4}";
                  conditions = [ "[CONNECTED] == true" ];
                }
              ] ++ lib.optional (cfg.nodes.${node}.ipv6 != null)
                {
                  name = "IPv6 ${node}";
                  group = "Nodes";
                  interval = "30s";
                  url = "icmp://${cfg.nodes.${node}.ipv6}";
                  conditions = [ "[CONNECTED] == true" ];
                }
              )
              (lib.attrNames cfg.nodes))
            # HTTP/HTTPS proxy
            ++ (lib.concatMap
              (node: [
                {
                  name = "HTTP ${node}";
                  group = "Reverse proxies";
                  interval = "60s";
                  url = "http://${node}.${cfg.domain}";
                  client.ignore-redirect = true;
                  conditions =
                    if cfg.tls.mode != "disabled"
                    then [ "[STATUS] == 301" ]
                    else [ "[STATUS] < 300" ];
                }
              ] ++ lib.optional (cfg.tls.mode != "disabled")
                {
                  name = "HTTPS ${node}";
                  group = "Reverse proxies";
                  interval = "60s";
                  url = "https://${node}.${cfg.domain}";
                  # Ignore certificate chain validity if using LE staging or manual certificate
                  client.insecure = (cfg.tls.mode == "acme" && cfg.tls.acme.server == "le-staging") || cfg.tls.mode == "manual";
                  conditions = [
                    "[STATUS] < 300"
                    "[CERTIFICATE_EXPIRATION] > 48h"
                  ];
                }
              )
              (builtins.attrNames (lib.filterAttrs (_: n: n.proxy) cfg.nodes)))
            ++ (map
              (node:
                {
                  name = "NS ${node}";
                  group = "Name Servers";
                  interval = "60s";
                  url = "${cfg.nodes.${node}.ipv4}";
                  dns = {
                    query-name = "${node}.${cfg.domain}";
                    query-type = "A";
                  };
                  conditions = [
                    "[DNS_RCODE] == NOERROR"
                    "[BODY] == ${cfg.nodes.${node}.ipv4}"
                  ];
                }
              )
              (builtins.attrNames (lib.filterAttrs (_: n: n.dnsRole != "none") cfg.nodes)))
            ++ (lib.concatMap
              (service:
                (map
                  (vhost:
                    {
                      name = "DNS ${vhost}";
                      group = "DNS";
                      interval = "60s";
                      url = "127.0.0.1";
                      dns = {
                        query-name = "${vhost}.${cfg.domain}";
                        query-type = "CNAME";
                      };
                      conditions = [
                        "[DNS_RCODE] == NOERROR"
                        "[BODY] == proxy.${cfg.domain}."
                      ];
                    }
                  )
                  (cfg.services.${service}.vhost)
                )
              )
              (builtins.attrNames (lib.filterAttrs (_: s: s.nodes != [ ]) cfg.services)))
          ;
        };
      };
      searx = {
        nodes = [ "trickster" ];
        port = 8081;
        scheme = "http";
        expose = "proxy";
        auth = "none";
        vhost = [ "searx" "search" ];
        otherOptions = {
          secretKeyFile = config.sops.secrets.searx-secret.path;
          openFirewall = true;
        };
      };
      pr-tracker = {
        nodes = [ "trickster" ];
        port = 8082;
        scheme = "http";
        expose = "proxy";
        auth = "none";
        otherOptions = {
          githubTokenFile = config.sops.secrets.pr-tracker-gh-token.path;
          userAgent = "pr-tracker (as3ii)";
        };
      };
    };

    tls = {
      mode = "acme";
      acme = {
        server = "le-production";
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        environmentFile = config.sops.templates."cloudflare-dns".path;
      };
    };
  };

  sops.secrets =
    let
      mkSecret = name: {
        format = "yaml";
        sopsFile = ../../secrets/homelab/general.yaml;
        key = name;
      };
    in
    {
      searx-secret = mkSecret "searx-secret";
      pr-tracker-gh-token = mkSecret "pr-tracker-gh-token";
      cf-dns-api-token = mkSecret "cf-dns-api-token";
    };
  sops.templates."cloudflare-dns".content = ''
    CLOUDFLARE_DNS_API_TOKEN="${config.sops.placeholder.cf-dns-api-token}"
  '';
}
