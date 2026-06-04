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
        version = "0.8.1";
        src = prev.fetchFromGitHub {
          owner = "Supreeeme";
          repo = "xwayland-satellite";
          rev = "a879e5e0896a326adc79c474bf457b8b99011027";
          hash = "sha256-BUE41HjLIGPjq3U8VXPjf8asH8GaMI7FYdgrIHKFMXA=";
        };
        cargoDeps = prev'.cargoDeps.overrideAttrs (_: prev'': {
          vendorStaging = prev''.vendorStaging.overrideAttrs {
            inherit (final') src;
            outputHash = "sha256-16L6gsvze+m7XCJlOA1lsPNELE3D364ef2FTdkh0rVY=";
          };
        });
      });
      niri = prev.niri.overrideAttrs (_: _: {
        version = "26.04-unstable-20260529";
        src = prev.fetchFromGitHub {
          owner = "niri-wm";
          repo = "niri";
          rev = "f9f43d826ab4014a7c302be28d7da33e12f5be37";
          hash = "sha256-t7lKVshV/srD0G06j4r5P5qj9zaDeZ9JYFCxHDGROZU=";
        };
        nativeInstallCheckInputs = [ ]; # Disables version check
        patches = [
          # https://github.com/niri-wm/niri/pull/3910
          (prev.fetchpatch2 {
            url = "https://github.com/niri-wm/niri/commit/164c9575cdb37ee8e57951eea7dac3ce957579c2.patch";
            hash = "sha256-JSwE3IwbDjcb6UXGcBUTBZORxO/Ij/lhqChEJZD0naA=";
          })
        ];
      });
    })
  ];
}
