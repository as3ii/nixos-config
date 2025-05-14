{ config, pkgs, lib, nixpkgs-unstable, nixpkgs-stable, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      unstable = import nixpkgs-unstable {
        config.allowUnfree = true;
      };
      stable = import nixpkgs-stable {
        config.allowUnfree = true;
      };
    })
    (self: super: {
      joshuto = super.callPackage ./joshuto.nix { };
    })
  ];
}
