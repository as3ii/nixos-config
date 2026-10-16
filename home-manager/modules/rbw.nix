{ config, pkgs, lib, options, ... }:

let
  cfg = config.rbw;
  hasSops = (builtins.hasAttr "sops" options);
  confpath = ''''${XDG_CONFIG_HOME-"$HOME/.config"}/rbw/config.json'';
  rbw = if !hasSops && cfg.email != null then cfg.package else
  pkgs.symlinkJoin {
    name = "rbw";
    paths = [ cfg.package ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    buildInputs = [ pkgs.replace-secret ];
    postBuild = ''
      wrapProgram $out/bin/rbw \
        --run '[ -e "${confpath}" ] && mv -f "${confpath}" "${confpath}.old"' \
        --run 'ln -s "${config.sops.templates."rbw-config.json".path}" "${confpath}"'
      wrapProgram $out/bin/rbw-agent \
        --run '[ -e "${confpath}" ] && mv -f "${confpath}" "${confpath}.old"' \
        --run 'ln -s "${config.sops.templates."rbw-config.json".path}" "${confpath}"'
    '';
  };
  rofi-rbw-wayland = pkgs.rofi-rbw.override {
    rbw = rbw;
    waylandSupport = true;
  };
in
{
  options.rbw = with lib.types; {
    package = lib.mkPackageOption pkgs.unstable "rbw" {
      extraDescription = ''
        Package providing the {command}`rbw` tool and its {command}`rbw-agent` daemon.
        This will be wrapped if `email-file` is used.
      '';
    };
    email = lib.mkOption {
      type = nullOr str;
      default = null;
      example = "user@domain.tld";
      description = ''
        Email to use to log in to bitwarden.
      '';
    };
  } // lib.optionalAttrs hasSops {
    sops-secret-name = lib.mkOption {
      type = nullOr str;
      default = null;
      example = "rbw-email";
      description = ''
        Name of the secret, used with `config.sops.secrets.''${sops-secret-name}`
      '';
    };
  };

  config = {
    assertions =
      if !hasSops then [
        {
          assertion = (cfg.email != null);
          message = "Set a valid rbw email.";
        }
      ] else [
        {
          assertion = !(cfg.email == null && cfg.sops-secret-name == null);
          message = "Set a valid rbw email or sops-secret-name.";
        }
        {
          assertion = (cfg.email == null || cfg.sops-secret-name == null);
          message = "Do not set both rbw email and sops-secret-name.";
        }
        {
          assertion = (cfg.sops-secret-name == null || builtins.hasAttr cfg.sops-secret-name config.sops.secrets);
          message = "Sops secret name for rbw do not exist";
        }
      ];

    programs.rbw = {
      enable = true;
      package = rbw;
      settings = lib.mkIf (cfg.email != null) {
        email = cfg.email;
        pinentry = pkgs.pinentry-qt;
      };
    };

    home.packages = [ rofi-rbw-wayland ];
  } // lib.optionalAttrs hasSops {
    sops.templates."rbw-config.json".content = lib.mkIf (cfg.sops-secret-name != null) ''
      {
        "email": "${config.sops.placeholder.${cfg.sops-secret-name}}",
        "lock_timeout": 300,
        "pinentry": "${lib.getExe pkgs.pinentry-qt}"
      }
    '';
  };
}
