{ config, lib, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = with pkgs; [
    podman-compose
    buildah
  ];

  hardware.nvidia-container-toolkit.enable = lib.mkIf (builtins.elem "nvidia" config.services.xserver.videoDrivers) true;
}

