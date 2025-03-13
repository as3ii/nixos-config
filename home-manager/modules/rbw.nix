{ config, pkgs, lib, ... }:

let
  cfg = config.rbw;
in
{
  options.rbw = {
    email = lib.mkOption {
      type = lib.types.str;
      example = "user@domain.tld";
      description = ''
        Email to use to log in to bitwarden.
      '';
    };
  };

  config = {
    programs.rbw = {
      enable = true;
      package = pkgs.unstable.rbw;
      settings = {
        email = cfg.email;
        pinentry = pkgs.pinentry-qt;
      };
    };

    home.packages = with pkgs; [
      rofi-rbw-wayland
    ];
  };
}
