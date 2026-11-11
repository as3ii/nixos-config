{ config, lib, ... }:

let
  cluster = config.cluster;
  secondaries = lib.filterAttrs (_: n: n.dnsRole == "secondary") cluster.nodes;
  secondaryNames = builtins.attrNames secondaries;

  nsName = i: "ns${toString i}.${cluster.domain}.";
  primaryNs = nsName 1;

  lastOctet = ipv4: lib.last (lib.splitString "." ipv4);
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

  subdomains = lib.mapAttrs'
    (name: node: {
      name = lastOctet node.ipv4;
      value.PTR = [ "${name}.${cluster.domain}." ];
    })
    cluster.nodes;
}
