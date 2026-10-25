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
        version = "0.8.3-20261025";
        src = prev.fetchFromGitHub {
          owner = "Supreeeme";
          repo = "xwayland-satellite";
          rev = "43e91dc6be074d1a88583082b2fcb0829ac36c16";
          hash = "sha256-I0h7d0bE+5syvQdhLXafzEPVqDospcAtagC1IqBJEyM=";
          # hash = prev.lib.fakeHash;
        };
        cargoDeps = prev'.cargoDeps.overrideAttrs (_: prev'': {
          vendorStaging = prev''.vendorStaging.overrideAttrs {
            inherit (final') src;
            outputHash = "sha256-gyQmdkWxnoaJzW1KN40ZmRTjVbfpt6tA8JHUMds35ag=";
          };
        });
      });
      niri = prev.niri.overrideAttrs (final': prev': {
        version = "26.04-unstable-20261025";
        src = prev.fetchFromGitHub {
          owner = "niri-wm";
          repo = "niri";
          rev = "75db0a3c700e7587bff847f995d5b0c0fe8c7efb";
          hash = "sha256-221lKWomR2hjeWo/t6BD0QHJh8FbN6+punXbwU4wilY=";
          # hash = prev.lib.fakeHash;
        };
        nativeInstallCheckInputs = [ ]; # Disables version check
        patches = [
          # https://github.com/niri-wm/niri/pull/3910
          (prev.fetchpatch2 {
            url = "https://github.com/niri-wm/niri/commit/164c9575cdb37ee8e57951eea7dac3ce957579c2.patch";
            hash = "sha256-JSwE3IwbDjcb6UXGcBUTBZORxO/Ij/lhqChEJZD0naA=";
          })
        ];
        cargoDeps = prev'.cargoDeps.overrideAttrs (_: prev'': {
          vendorStaging = prev''.vendorStaging.overrideAttrs {
            inherit (final') src;
            outputHash = "sha256-4VQqTrVB6p8M3U7xqF+K6vSKrQcqhW+OnZyAp6j/fGA=";
          };
        });
      });
    })
  ];
}
