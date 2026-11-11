{
  description = "Nixos config flake";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-unstable";

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-26.05";
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

    disko = {
      url = "github:nix-community/disko"; # Using master instead of latest because latest is too old
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:nix-community/preservation";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dns = {
      url = "github:nix-community/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
    , disko
    , preservation
    , deploy-rs
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

        packages =
          let
            cross-compile = false; # Whether to cross-compile or use binfmt
            cross-compile-mod = nixpkgs.lib.mkIf cross-compile {
              nixpkgs.config.allowUnsupportedSystem = true;
              nixpkgs.hostPlatform = "aarch64-linux";
              nixpkgs.buildPlatform = system;
            };
          in
          {
            # https://hydra.nixos.org/job/nixos/release-26.05/nixos.sd_image_new_kernel_no_zfs.aarch64-linux/latest/download-by-type/file/sd-image
            rpi3-image = (self.nixosConfigurations.rpi3.extendModules {
              modules = [ cross-compile-mod ];
            }).config.system.build.sdImage;

            #trickster = self.nixosConfigurations.trickster.config.system.build.diskoImagesScript;

            # tricksterVM = (self.nixosConfigurations.trickster.extendModules {
            #   modules = [
            #     "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
            #   ];
            # }).config.system.build.diskoImagesScript;
          };

        # Filter nodes, keep only the ones that have the same architecture
        checks = deploy-rs.lib.${system}.deployChecks (self.deploy // {
          nodes = pkgs.lib.filterAttrs (_: value: value.profiles.system.path.system == system) self.deploy.nodes;
        });
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
                home-manager = {
                  extraSpecialArgs = inputs // { inherit system; };
                  # Fix custom rbw module
                  backupFileExtension = "bak";
                  overwriteBackup = true;
                };
              }
              (import ./nix/pkgs)
              ./hosts/thinkpad/configuration.nix
            ];
          };

          rpi3 = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            specialArgs = inputs // { user = "as3ii"; };

            modules = [
              nixos-hardware.nixosModules.raspberry-pi-3
              preservation.nixosModules.default
              sops-nix.nixosModules.sops
              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
              (import ./nix/pkgs)
              (import ./hosts/rpi3)
              (import ./inventories/homelab)
            ];
          };

          trickster = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = inputs // { user = "as3ii"; };

            modules = [
              nixos-hardware.nixosModules.common-pc-ssd
              nixos-hardware.nixosModules.common-cpu-intel
              nixos-hardware.nixosModules.common-gpu-intel
              disko.nixosModules.disko
              preservation.nixosModules.default
              sops-nix.nixosModules.sops
              (import ./nix/pkgs)
              (import ./hosts/trickster)
              (import ./inventories/homelab)
            ];
          };
        };

        deploy.nodes =
          let
            getPath = host:
              deploy-rs.lib.${self.nixosConfigurations.${host}.pkgs.stdenv.hostPlatform.system}.activate.nixos
                self.nixosConfigurations.${host};
          in
          {
            rpi3 = {
              user = "root";
              sshUser = "as3ii";
              interactiveSudo = true;
              hostname = "rpi3";
              profiles.system.path = getPath "rpi3";
            };

            trickster = {
              user = "root";
              sshUser = "as3ii";
              interactiveSudo = true;
              hostname = "trickster";
              profiles.system.path = getPath "trickster";
            };
          };
      };
    };
}
