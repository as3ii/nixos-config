{ config, lib, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune = {
      enable = true;
      dates = "weelly"; # The default
      flags = [ "--all" ];
    };
  };

  environment.systemPackages = with pkgs; [
    podman-compose
    buildah
  ];

  hardware.nvidia-container-toolkit.enable = lib.mkIf (builtins.elem "nvidia" config.services.xserver.videoDrivers) true;
}
