{ ... }:

{
  # Add IP fallback, useful if the system have a local DNS server that may stop working
  services.timesyncd = {
    enable = true;
    servers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
      "93.94.88.50"
      "95.110.254.234"
      "162.159.200.1"
      "162.159.200.123"
    ];
  };
}
