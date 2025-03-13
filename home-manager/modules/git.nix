{ config, lib, ... }:

let
  cfg = config.git;
in
{
  options.git = {
    userName = lib.mkOption {
      type = lib.types.str;
      description = "Default user name.";
    };
    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "Default user email.";
    };
    signingKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "GPG key to use.";
    };
    includes = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
      example = lib.literalExpression ''
        [
          { path = "~/path/to/config.inc"; }
          {
          path = "~/path/to/conditional.inc";
          condition = "gitdir:~/src/dir";
          }
        ]
      '';
      description = ''
        List of configuration files to include.
        See: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.git.includes
      '';
    };
  };

  config = {
    programs.git = {
      enable = true;
      attributes = [
        "* text=auto eol=lf"
      ];
      extraConfig = {
        init.defaultBranch = "master";
      };
      lfs.enable = true;

      userName = cfg.userName;
      userEmail = cfg.userEmail;
      signing = {
        key = cfg.signingKey;
        signByDefault = cfg.signingKey != null;
      };
    };

    home.shellAliases = {
      gita = "git add";
      gotad = "git add -p";
      gitc = "git commit -S";
      gitd = "git diff";
      gitp = "git push";
      gits = "git status";
    };
  };
}
