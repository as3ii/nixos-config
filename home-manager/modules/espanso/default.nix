{ config, pkgs, ... }:

let
  lang = config.services.xserver.xkb.layout or config.console.keyMap or "us";
in
{
  services.espanso = {
    enable = true;
    #package = pkgs.espanso;
    package = pkgs.espanso-wayland;
    configs = {
      keyboard_layout = {
        rules = "evdev";
        model = "pc105";
        layout = "${lang}";
      };
      toggle_key = "RIGHT_ALT";
      search_shortcut = "ALT+SHIFT+SPACE";
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

  home.packages = with pkgs; [
    #xdotool
    #xsel
    wl-clipboard
    ydotool
  ];
}
