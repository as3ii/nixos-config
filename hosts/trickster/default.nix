{ ... }:

{
  imports = [
    ../../modules/base.nix
    ../../modules/kernel-hardening.nix
    ../../modules/services/openssh.nix
    ../common/deploy-rs-keys.nix
    ../common/timesyncd.nix
    ./configuration.nix
    ./disko.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./preservation.nix
  ];
}
