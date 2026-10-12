{ ... }:

{
  imports = [
    ./overlays.nix
  ];

  nixpkgs.config.allowUnfree = true;
}
