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
        version = "0.8.3-20260925";
        src = prev.fetchFromGitHub {
          owner = "Supreeeme";
          repo = "xwayland-satellite";
          rev = "63cdf17f17b4ee231ef862690048549f218e8e0e";
          hash = "sha256-FBRBINpTMhkhVm9irSqeWKmI8/QMyXcTRxHeCMVvxdc=";
          # hash = prev.lib.fakeHash;
        };
        cargoDeps = prev'.cargoDeps.overrideAttrs (_: prev'': {
          vendorStaging = prev''.vendorStaging.overrideAttrs {
            inherit (final') src;
            outputHash = "sha256-gMGFvnbxM3hD5fmkSimaFd87GEf6BXFe/MGjoS6VNVU=";
          };
        });
      });
      niri = prev.niri.overrideAttrs (final': prev': {
        version = "26.04-unstable-20261012";
        src = prev.fetchFromGitHub {
          owner = "niri-wm";
          repo = "niri";
          rev = "90af637e466687ebce85d5e037c83871a1c0376a";
          hash = "sha256-i5vn7WnkeIiMVZO/kQTlZWIkaZIbSExhyVc9WOhAFeY=";
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
            outputHash = "sha256-JJfJ8o5yuI8mfXDkEfdCVcqQpxIXICV3dji7HoLgKBI=";
          };
        });
      });
    })
  ];
}
