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
        version = "0.8.2";
        src = prev.fetchFromGitHub {
          owner = "Supreeeme";
          repo = "xwayland-satellite";
          rev = "8d135d3b2854b30fd01ea6cd6c27e523dd50a839";
          hash = "sha256-Mb7jpqnrcYCfNSItIkkHpuR3YxWFxPuIBfcwNKlRBkk=";
        };
        cargoDeps = prev'.cargoDeps.overrideAttrs (_: prev'': {
          vendorStaging = prev''.vendorStaging.overrideAttrs {
            inherit (final') src;
            outputHash = "sha256-Saa3SRsQuY6u6pfBGezaEExOt/ReblnrG7pAXjA6Dk8=";
          };
        });
      });
      niri = prev.niri.overrideAttrs (final': prev': {
        version = "26.04-unstable-20260720";
        src = prev.fetchFromGitHub {
          owner = "niri-wm";
          repo = "niri";
          rev = "7f26c3ee804fb6ed458ef7fb0e3c794f14e0b3bc";
          hash = "sha256-9EMn69JBcFWFgUM7f0VBAX+jBby5b9H3M59U75+5yI4=";
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
            outputHash = "sha256-HypBB3PL4nVFMNH2+jEK0+dG9dJ920nHi8GwRoeH/v4=";
          };
        });
      });
    })
  ];
}
