{ config, pkgs, ... }:

{
  devShells.default = pkgs.mkShell {
    buildInputs = with pkgs; [
      sops
    ] ++ config.pre-commit.settings.enabledPackages;
    shellHook = "${config.pre-commit.installationScript}";
  };
}
