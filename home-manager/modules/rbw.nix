{ pkgs, ... }:

{
  programs.rbw = {
    enable = true;
    package = pkgs.unstable.rbw;
    settings = {
      #email = "";
      pinentry = pkgs.pinentry-qt;
    };
  };

  home.packages = with pkgs; [
    rofi-rbw-wayland
  ];
}
