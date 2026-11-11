{ lib, config, pkgs, ... }:

let
  cluster = config.cluster;

  selfHostName = config.networking.hostName;
  selfNode = cluster.nodes.${selfHostName};
  enableBind = builtins.length (builtins.attrNames (lib.filterAttrs (_: n: n.dnsRole == "none") cluster.nodes)) != builtins.length (builtins.attrNames cluster.nodes);
  primaryDns = lib.findFirst (n: n.dnsRole == "primary") null (builtins.attrValues cluster.nodes);
  secondariesDns = lib.filterAttrs (_: n: n.dnsRole == "secondary") cluster.nodes;
  badlist1 = pkgs.fetchurl {
    # Use this to avoid downloading the whole repository
    url = "https://raw.githubusercontent.com/StevenBlack/hosts/f5e8defaaf8ea01d8b82178c0fb626eb9f09789d/alternates/fakenews-gambling/hosts";
    # hash = lib.fakeHash;
    hash = "sha256-wzLG7WpQvBkRKwh4flbIiMgt6Ydx5HanO0r6FqwyLJw=";
  };
  badlist2 = pkgs.fetchurl {
    # Use this to avoid downloading the whole repository
    url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/eb7db8ed27237af2f3c0cb79c9c735e3e076dbad/wildcard/pro-onlydomains.txt";
    # hash = lib.fakeHash;
    hash = "sha256-9JCw6Cc9X/ClVJGBHxc+H7sEC/xrZvGlNvVA78F5Mhk=";
  };
in
{
  imports = [ ../services/dns/bind-with-zones.nix ];

  config = lib.mkIf enableBind {
    cluster.services.doh = {
      nodes = lib.mkForce (builtins.attrNames (lib.filterAttrs (_: n: n.dnsRole != "none") cluster.nodes));
      port = config.bind.doh.port;
      scheme = "https";
      expose = "proxy";
      auth = "none";
      #vhost = "doh";
    };

    bind-with-zones =
      let
        self = config.bind-with-zones;
      in
      {
        enable = selfNode.dnsRole != "none";
        master = selfNode.dnsRole == "primary";
        slaves = lib.optionals self.master (
          lib.flatten (lib.mapAttrsToList (_: v: [ v.ipv4 ] ++ lib.optional (v.ipv6 != null) v.ipv6) secondariesDns)
        );
        masters = lib.optionals (!self.master) (
          lib.optional (primaryDns != null) primaryDns.ipv4
          ++ lib.optional (primaryDns != null && primaryDns.ipv6 != null) primaryDns.ipv6
        );
        zoneFiles = cluster.zoneFiles;
      };

    networking.nameservers = (
      if selfNode.dnsRole == "none" then
        (lib.mkDefault [ primaryDns.ipv4 ]
          ++ lib.optional (primaryDns.ipv6 != null) primaryDns.ipv6
          ++ lib.flatten (lib.mapAttrsToList (_: v: [ v.ipv4 ] ++ lib.optional (v.ipv6 != null) v.ipv6) secondariesDns))
      else
        [ "127.0.0.1" "::1" ]
    );

    # DoH with ephemeral key, port 8443
    bind.doh = {
      enable = true;
      openPort = true;
    };
    bind.blockListFile = pkgs.runCommand "blocklist-merged.txt"
      {
        nativeBuildInputs = with pkgs; [ coreutils ];
      } ''
      # Download and cleanup the 2 file lists
      sed "s/\s*#.*//; /^\s*\$/d; s/_/-/g; /^127.0.0.1 .*/d; /^255.255.255.255 .*/d; /^::1 .*/d; /^f[ef][0-9]\{0,2\}:.*/d; /0.0.0.0 0.0.0.0/d; s/^0.0.0.0 //" "${badlist1}" > one
      sed "s/\s*#.*//; /^\s*\$/d; s/_/-/g" "${badlist2}" > two
      cat one two | LC_ALL=C sort -u >> $out
    '';
  };
}
