{ ... }:

{
  # Enable networking
  networking = {
    networkmanager.enable = true;
    enableIPv6 = true;
  };

  # disable phone modem
  systemd.services.modem-manager.enable = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
}
