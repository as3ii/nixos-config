{
  description = "Nixos config flake";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager.follows = "home-manager-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/v4.4.0";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    { self
    , nixpkgs
      # , nixpkgs-stable
      # , nixpkgs-unstable
    , nixos-hardware
    , home-manager
      # , home-manager-stable
      # , home-manager-unstable
    , sops-nix
    , flake-parts
    , ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.git-hooks-nix.flakeModule ];

      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { pkgs, system, ... }: {
        formatter = pkgs.nixpkgs-fmt;
        imports = [
          ./nix/git-hooks.nix
          ./nix/devshells.nix
        ];

        packages = {
          # https://hydra.nixos.org/job/nixos/release-25.05/nixos.sd_image_new_kernel_no_zfs.aarch64-linux/latest/download-by-type/file/sd-image
          rpi3-image = (self.nixosConfigurations.rpi3.extendModules {
            modules = [
              {
                nixpkgs.config.allowUnsupportedSystem = true;
                nixpkgs.hostPlatform.system = "aarch64-linux";
                nixpkgs.buildPlatform.system = system;
              }
            ];
          }).config.system.build.sdImage;
        };
      };

      flake = {
        nixosConfigurations = {
          as3ii-thinkpad-nixos = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            specialArgs = inputs;

            modules = [
              nixos-hardware.nixosModules.common-pc-ssd
              nixos-hardware.nixosModules.common-cpu-amd
              nixos-hardware.nixosModules.common-gpu-amd
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
              {
                nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" "gccarch-znver4" "gccarch-x86-64-v4" ];
                nixpkgs.config.allowUnfree = true;
                home-manager.extraSpecialArgs = inputs // { inherit system; };
              }
              (import ./nix/pkgs)
              ./hosts/thinkpad/configuration.nix
            ];
          };

          rpi3 = nixpkgs.lib.nixosSystem rec {
            system = "aarch64-linux";
            specialArgs = inputs;

            modules = [
              nixos-hardware.nixosModules.raspberry-pi-3
              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
              { nixpkgs.config.allowUnfree = true; }
              (import ./nix/pkgs)
              ./hosts/rpi3/configuration.nix
            ];
          };
        };
      };
    };
}
