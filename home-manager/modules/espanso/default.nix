{ config, pkgs, lib, ... }:

let
  cfg = config.espanso;
  lang = config.services.xserver.xkb.layout or config.console.keyMap or "us";
  pkg-wayland = with pkgs; [
    wl-clipboard
    ydotool
  ];
  pkg-xorg = with pkgs; [
    xdotool
    xsel
  ];
in
{
  options.espanso = {
    wayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        Enable wayland support (disables Xorg support).
      '';
    };
  };

  config = {
    services.espanso = {
      enable = true;
      package = if cfg.wayland then pkgs.espanso-wayland else pkgs.espanso;
      configs = {
        default = {
          keyboard_layout = {
            rules = "evdev";
            model = "pc105";
            layout = "${lang}";
          };
          toggle_key = "RIGHT_ALT";
          search_shortcut = "ALT+SHIFT+SPACE";
        };
      };
      matches = {
        #base = builtins.fromYAML (builtins.readFile ./base.yml);
      };
    };

    xdg.configFile."espanso/match/base.yml".source = ./base.yml;
    xdg.configFile."espanso/match/packages" = {
      source = ./packages;
      recursive = true;
    };

    home.packages = if cfg.wayland then pkg-wayland else pkg-xorg;
  };
}
