{ pkgs, ... }:

{
  # Enable networking
  networking = {
    networkmanager = {
      enable = true;
      dispatcherScripts = [
        {
          # disable IPv6 when a VPN is enabled
          source = pkgs.writeText "vpn-ipv6" ''
            case "$2" in
                vpn-up)
                    echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
                    ;;
                vpn-dpwn)
                    echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6
                    ;;
            esac
          '';
          type = "basic";
        }
      ];
    };
    enableIPv6 = true;
  };

  # disable phone modem
  systemd.services.modem-manager.enable = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
}
