{ config, pkgs, ... }:

{
  devShells.default = pkgs.mkShell {
    buildInputs = with pkgs; [
      nh
      deploy-rs
      just
      nix-output-monitor
      sops
      age
      yq-go
    ] ++ config.pre-commit.settings.enabledPackages;
    shellHook = ''
      ${config.pre-commit.installationScript}
      export NH_FLAKE="''$PWD";
    '';
  };
}
