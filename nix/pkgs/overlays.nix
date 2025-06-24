{ nixpkgs-unstable, nixpkgs-stable, ... }:

{
  nixpkgs.overlays = [
    (_: _: {
      unstable = import nixpkgs-unstable {
        config.allowUnfree = true;
      };
      stable = import nixpkgs-stable {
        config.allowUnfree = true;
      };
    })
    (_: super: {
      joshuto = super.callPackage ./joshuto.nix { };
    })
  ];
}
