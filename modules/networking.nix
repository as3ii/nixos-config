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
        {
          # Set WiFi regulatory domain
          source = pkgs.writeText "reg-it" ''
            case "$1" in
                wlp*)
                    if [ "$2" = "pre-up" ]; then
                        ${pkgs.iw}/bin/iw reg set IT
                    fi
                    ;;
            esac
          '';
          type = "pre-up";
        }
      ];
    };
    enableIPv6 = true;
  };

  # disable phone modem
  systemd.services.ModemManager.enable = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
}
