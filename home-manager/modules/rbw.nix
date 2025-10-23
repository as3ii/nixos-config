{ config, pkgs, lib, ... }:

let
  cfg = config.rbw;
  confpath = ''''${XDG_CONFIG_HOME-"$HOME/.config"}/rbw/config.json'';
  rbw-wrapper = cfg.package.overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ] ++ [ pkgs.makeWrapper ];
    # Rename the home-manager config symlink, copy as a file, patch the config
    # and then actually run rbw. At every execution of rbw/rbw-agent
    postInstall = oldAttrs.postInstall + ''
      makeWrapper ${cfg.package}/bin/rbw $out/bin/rbw \
        --run '[ -h "${confpath}" ] && mv -f "${confpath}" "${confpath}.lnk"' \
        --run '[ -h "${confpath}.lnk" ] && install -m 600 "${confpath}.lnk" "${confpath}"' \
        --run '${pkgs.replace-secret}/bin/replace-secret "@email_placeholder@" "${cfg.email-file}" "${confpath}"'
      makeWrapper ${cfg.package}/bin/rbw-agent $out/bin/rbw-agent \
        --run '[ -h "${confpath}" ] && mv -f "${confpath}" "${confpath}.lnk"' \
        --run '[ -h "${confpath}.lnk" ] && install -m 600 "${confpath}.lnk" "${confpath}"' \
        --run '${pkgs.replace-secret}/bin/replace-secret "@email_placeholder@" "${cfg.email-file}" "${confpath}"'
    '';
  });
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
    email-file = lib.mkOption {
      type = nullOr path;
      default = null;
      example = /path/to/email-file.txt;
      description = ''
        File containing the email.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.email == null && cfg.email-file == null);
        message = "Set a valid email-file or email.";
      }
      {
        assertion = (cfg.email == null || cfg.email-file == null);
        message = "Do not set both email and email-file.";
      }
    ];
    programs.rbw = {
      enable = true;
      package = if cfg.email-file != null then rbw-wrapper else cfg.package;
      settings = {
        email = if cfg.email-file != null then "@email_placeholder@" else cfg.email;
        pinentry = pkgs.pinentry-qt;
      };
    };

    xdg.configFile."rbw/config.json".force = true;

    home.packages = with pkgs; [
      rofi-rbw-wayland
    ];
  };
}
