{ config, lib, ... }:

let
  cluster = config.cluster;

  configureNetworks = builtins.length (builtins.attrNames (lib.filterAttrs (_: n: n.interface == null) cluster.nodes)) != builtins.length (builtins.attrNames cluster.nodes);

  selfHostName = config.networking.hostName;
  selfNode = cluster.nodes.${selfHostName};
in
{
  config = lib.mkIf (configureNetworks && selfNode.interface != null) {
    networking = lib.mkDefault {
      networkmanager.enable = false;
      useDHCP = false;

      enableIPv6 = true;
      nftables.enable = true;
      firewall = {
        enable = true;
        logReversePathDrops = true;
      };
    };

    # https://wiki.nixos.org/wiki/Systemd/networkd
    systemd.network = {
      enable = true;
      networks."30-${selfNode.interface}" = {
        matchConfig.Name = selfNode.interface;
        linkConfig.RequiredForOnline = "routable";
        networkConfig = {
          DHCP = "no";
          IPv6AcceptRA = selfNode.ipv6 == null;
          DNS = config.networking.nameservers;
          Domains = [ cluster.domain ];
        };
        addresses = [
          { Address = "${selfNode.ipv4}/${toString cluster.ipv4PrefixLength}"; }
        ] ++ lib.optional (selfNode.ipv6 != null) {
          Address = "${selfNode.ipv6}/${toString cluster.ipv6PrefixLength}";
        };
        routes = lib.optional (cluster.ipv4Gateway != null)
          {
            Destination = "0.0.0.0/0";
            Gateway = cluster.ipv4Gateway;
          } ++ lib.optional (selfNode.ipv6 != null && cluster.ipv6Gateway != null)
          {
            Destination = "::/0";
            Gateway = cluster.ipv6Gateway;
          };
        routingPolicyRules = [
          {
            # Fix tailscale LAN issues with --accept-routes
            To = cluster.ipv4Network;
            Table = "main";
            Priority = 2500;
            Family = "ipv4";
          }
        ];
      };
    };
  };
}
