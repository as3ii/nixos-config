{ ... }:

{
  imports = [
    ../../modules/base.nix
    ../../modules/kernel-hardening.nix
    ../../modules/services/openssh.nix
    ../common/deploy-rs-keys.nix
    ../common/timesyncd.nix
    ./configuration.nix
    ./hardware-configuration.nix
    ./preservation.nix
    ./sdimage-config.nix
  ];
}
