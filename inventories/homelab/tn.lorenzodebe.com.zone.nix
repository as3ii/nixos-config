{ dns, config, lib, ... }:

let
  cluster = config.cluster;
  maybePrimary = builtins.attrValues (lib.filterAttrs (_: n: n.dnsRole == "primary") cluster.nodes);
  primary = if (maybePrimary != [ ]) then builtins.head maybePrimary else { };
  secondaries = lib.filterAttrs (_: n: n.dnsRole == "secondary") cluster.nodes;
  secondaryNames = builtins.attrNames secondaries;

  nsName = i: "ns${toString i}";
  primaryNs = nsName 1;

  proxyNames = builtins.attrNames (lib.filterAttrs (_: n: n.proxy) cluster.nodes);
in
{
  useOrigin = true;
  TTL = cluster.ttl;

  SOA = {
    nameServer = primaryNs;
    adminEmail = cluster.adminEmail;
    serial = cluster.serial;
    refresh = 6 * 60 * 60; # 6h
    retry = 30 * 60; # 30m
    expire = 30 * 24 * 60 * 60; # 30d
    minimum = if (cluster.ttl < 60 * 60) then cluster.ttl else 60 * 60; # 1h
  };

  NS = [ primaryNs ] ++ lib.imap0 (i: _: nsName (i + 2)) secondaryNames;

  # (nodes + services wildcard) // primary nameserver // secondary nameservers // proxy
  subdomains = (
    lib.mapAttrs
      (
        name: node:
          dns.lib.combinators.host node.ipv4 node.ipv6
            // { subdomains."*".CNAME = [ name ]; }
      )
      cluster.nodes
  )
  // { "${primaryNs}" = dns.lib.combinators.host primary.ipv4 primary.ipv6; }
  // lib.listToAttrs (lib.imap0
    (i: name: {
      name = nsName (i + 2);
      value = dns.lib.combinators.host secondaries.${name}.ipv4 secondaries.${name}.ipv6;
    })
    secondaryNames)
  // lib.optionalAttrs (proxyNames != [ ]) {
    proxy = {
      A = map (n: cluster.nodes.${n}.ipv4) proxyNames;
      AAAA = lib.flatten (map (n: lib.optional (cluster.nodes.${n}.ipv6 != null) cluster.nodes.${n}.ipv6) proxyNames);
    };
    "*".CNAME = [ "proxy" ];
  }
  // lib.optionalAttrs (cluster.auth.enable) {
    "${cluster.auth.vhost}".CNAME = [ "proxy" ];
  };
}
