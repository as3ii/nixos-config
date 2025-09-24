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
  # Waiting for PR: https://github.com/NixOS/nixpkgs/pull/439793
  #hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
  #  version = "580.82.07";
  #  sha256_64bit = "sha256-Bh5I4R/lUiMglYEdCxzqm3GLolQNYFB0/yJ/zgYoeYw=";
  #  sha256_aarch64 = "sha256-or3//aV4TQcPDgcLxFB75H/kB8n+3RzwTO1C2ZbJAJI=";
  #  openSha256 = "sha256-8/7ZrcwBMgrBtxebYtCcH5A51u3lAxXTCY00LElZz08=";
  #  settingsSha256 = "sha256-lx1WZHsW7eKFXvi03dAML6BoC5glEn63Tuiz3T867nY=";
  #  persistencedSha256 = "sha256-1JCk2T3H5NNFQum0gA9cnio31jc0pGvfGIn2KkAz9kA=";
  #};
}
