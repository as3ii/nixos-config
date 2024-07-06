{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, nixpkgs-unstable, ... }@inputs:
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
  in {
    nixosConfigurations.as3ii-thinkpad-nixos = nixpkgs.lib.nixosSystem {
      inherit pkgs system;

      #specialArgs = {inherit inputs;};
      modules = [
        (import ./configuration.nix inputs)
        # inputs.home-manager.nixosModules.default
      ];
    };
  };
}

