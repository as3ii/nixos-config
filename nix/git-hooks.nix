{ ... }:

{
  pre-commit = {
    check.enable = true;

    settings = {
      addGcRoot = true;

      hooks = {
        # Shell scripts
        check-executables-have-shebangs.enable = true;
        check-shebang-scripts-are-executable.enable = true;
        shellcheck = {
          enable = true;
          excludes = [
            ".envrc"
          ];
        };
        # Secrets
        pre-commit-hook-ensure-sops.enable = true;
        detect-private-keys.enable = true;
        ripsecrets.enable = true;
        # Misc
        check-added-large-files.enable = true;
        end-of-file-fixer.enable = true;
        trim-trailing-whitespace.enable = true;
        typos = {
          enable = true;
          settings.config = {
            default.extend-words = {
              odf = "odf";
            };
          };
          excludes = [
            "secrets/"
          ];
        };
        # Nix
        deadnix.enable = true;
        nil.enable = true;
        nixpkgs-fmt.enable = true;
      };
    };
  };
}
