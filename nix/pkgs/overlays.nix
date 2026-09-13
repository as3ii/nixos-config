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
        version = "0.8.2-20260808";
        src = prev.fetchFromGitHub {
          owner = "Supreeeme";
          repo = "xwayland-satellite";
          rev = "3bc915f09dd62bb2651a715114f9d140344bc6c1";
          hash = "sha256-hF2atQzapHBLX5NFqJMcKZAWHfGkKQeNu1eQr46+AGg=";
          # hash = prev.lib.fakeHash;
        };
        cargoDeps = prev'.cargoDeps.overrideAttrs (_: prev'': {
          vendorStaging = prev''.vendorStaging.overrideAttrs {
            inherit (final') src;
            outputHash = "sha256-Saa3SRsQuY6u6pfBGezaEExOt/ReblnrG7pAXjA6Dk8=";
          };
        });
      });
      niri = prev.niri.overrideAttrs (final': prev': {
        version = "26.04-unstable-20260819";
        src = prev.fetchFromGitHub {
          owner = "niri-wm";
          repo = "niri";
          rev = "b0eb8ad8c80094de34abd88c109aea421461622b";
          hash = "sha256-dzLsp/FvMerhsjfsWtFK/BTlJ5FZwLWlhsFJRRxpmbU=";
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
            outputHash = "sha256-aNovCzrTtmqTO33YtZap47npdN73zXC1bap5q5dZvZk=";
          };
        });
      });
    })
  ];
}
