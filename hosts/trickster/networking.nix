{ lib, ... }:

{
  # https://wiki.nixos.org/wiki/Systemd/networkd
  systemd.network = {
    enable = true;

    # Define bridge and/or bonding
    netdevs = {
      # https://docs.kernel.org/networking/bonding.html
      # https://www.freedesktop.org/software/systemd/man/latest/systemd.netdev.html?#[Bond]%20Section%20Options
      "10-bond0" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond0";
        };
        bondConfig = {
          # Basic failover, no configuration required on the switch
          Mode = "active-backup";
          # FailOverMACPolicy = "none"; # none is the default

          # This is for 802.3ad, requires configuration on the switch side
          # Mode = "802.3ad";
          # TransmitHashPolicy = "layer2+3";
          # LACPTransmitRate = "fast";

          MIIMonitorSec = "100ms"; # MII link monitoring frequency
        };
      };
    };

    # Initialize interfaces
    # https://www.freedesktop.org/software/systemd/man/latest/systemd.network.html
    networks = {
      "30-enp1s0" = {
        matchConfig.Name = "enp1s0";
        networkConfig.Bond = "bond0";
      };
      "30-enp3s0" = {
        matchConfig.Name = "enp3s0";
        networkConfig.Bond = "bond0";
      };
      # Disabled, handled by inventory management
      "40-bond0" = lib.mkIf false {
        matchConfig.Name = "bond0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true; # use SLAAC
        };
        # https://www.freedesktop.org/software/systemd/man/latest/systemd.network.html#RequiredForOnline=
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
