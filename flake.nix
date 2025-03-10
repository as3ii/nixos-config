{
  description = "Nixos config flake";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager.follows = "home-manager-unstable";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , nixpkgs-unstable
    , nixos-hardware
    , home-manager
    , home-manager-stable
    , home-manager-unstable
    , ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;

        config.allowUnfree = true;

        overlays = [
          (self: super: {
            unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
            stable = import nixpkgs-stable {
              inherit system;
              config.allowUnfree = true;
            };
          })
        ];
      };

      homeManagerWithInputs = { home-manager.extraSpecialArgs = inputs // { inherit system; }; };
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

      nixosConfigurations = {
        as3ii-thinkpad-nixos = nixpkgs.lib.nixosSystem {
          inherit pkgs system;

          specialArgs = inputs;
          modules = [
            nixos-hardware.nixosModules.common-pc-ssd
            nixos-hardware.nixosModules.common-cpu-amd
            nixos-hardware.nixosModules.common-gpu-amd
            homeManagerWithInputs
            ./hosts/thinkpad/configuration.nix
          ];
        };
      };
    };
}

# vim: sw=2
