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
        version = "25.11-unstable-20260327";
        src = prev.fetchFromGitHub {
          owner = "niri-wm";
          repo = "niri";
          rev = "8f48f56fe19918b5cfa02e5d68a47ebaf7bf3dee";
          hash = "sha256-FC9eYtSmplgxllCX4/3hJq5J3sXWKLSc7at8ZUxycVw=";
        };
        nativeInstallCheckInputs = [ ]; # Disables version check
      });
    })
  ];
}
