{ config, nixpkgs-unstable, ... }:

{
  nixpkgs.config = {
    packageOverrides = pkgs: {
      unstable = {
        inherit nixpkgs-unstable;
        config = config.nixpkgs.config;
      };
    };
  };
}
