{ config, ... }:

{
  nixpkgs.config = {
    packageOverrides = pkgs: {
      unstable = import (
        fetchTarball https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz
      ) {
        config = config.nixpkgs.config;
      };
    };
  };
}
