{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome
      jetbrains-mono
      nerd-fonts.jetbrains-mono
    ];
    fontDir.enable = true;
  };

}
