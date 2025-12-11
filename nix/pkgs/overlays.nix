{ nixpkgs-unstable, nixpkgs-stable, ... }:

{
  nixpkgs.overlays = [
    # allows the use of pkgs.stable and pkgs.unstable
    (_: prev: {
      unstable = import nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
      stable = import nixpkgs-stable {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })
    # other overlays
    (_: prev: {
      joshuto = prev.callPackage ./joshuto.nix { };
      xwayland-satellite = prev.xwayland-satellite.overrideAttrs (final': prev': {
        version = "0.8-20251211";
        src = prev.fetchFromGitHub {
          owner = "Supreeeme";
          repo = "xwayland-satellite";
          rev = "f0ad674b7009a6afd80cea59d4fbf975dd68ee95";
          hash = "sha256-HtTPbV6z6AJPg2d0bHaJKFrnNha+SEbHvbJafKAQ614=";
        };
        cargoDeps = prev'.cargoDeps.overrideAttrs (_: prev'': {
          vendorStaging = prev''.vendorStaging.overrideAttrs {
            inherit (final') src;
            outputHash = "sha256-HGrMjNIsUqh8AFtSABk615x4B9ygrVEn26V0G1kX/nA=";
          };
        });
      });
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
