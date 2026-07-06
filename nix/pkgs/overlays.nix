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
        version = "0.8.1-unstable-20260612";
        src = prev.fetchFromGitHub {
          owner = "Supreeeme";
          repo = "xwayland-satellite";
          rev = "8575d0ef55d70f9b4c46b6bffb3accf912217e1e";
          hash = "sha256-28696iIw8uE0ZUyFTtzhEM8xMh85clCYypMxkvUi+sc=";
        };
        cargoDeps = prev'.cargoDeps.overrideAttrs (_: prev'': {
          vendorStaging = prev''.vendorStaging.overrideAttrs {
            inherit (final') src;
            outputHash = "sha256-jbEihJYcOwFeDiMYlOtaS8GlunvSze80iWahDj1qDrs=";
          };
        });
      });
      niri = prev.niri.overrideAttrs (final': prev': {
        version = "26.04-unstable-20260618";
        src = prev.fetchFromGitHub {
          owner = "niri-wm";
          repo = "niri";
          rev = "49fc6117fd6c043adaa2ead316b82db5ed735d36";
          hash = "sha256-Ii/koEm/sRyg65qbAQWqEgboSEIhdH0EL4KglAc14p0=";
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
            outputHash = "sha256-jGORNwJ/F9UrajObXdGLbOTGEpCv919puUuWojbuVwo=";
          };
        });
      });
    })
  ];
}
