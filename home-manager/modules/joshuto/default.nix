{ pkgs, ... }:

{
  programs.joshuto = {
    enable = true;
    keymap = builtins.fromTOML (builtins.readFile ./keymap.toml);
    mimetype = builtins.fromTOML (builtins.readFile ./mimetype.toml);
    settings = builtins.fromTOML (builtins.readFile ./joshuto.toml);
  };

  xdg.configFile."joshuto/preview_file.sh" = {
    source = ./preview_file.sh;
    executable = true;
  };

  xdg.configFile."joshuto/libreoffice.sh" = {
    source = ./libreoffice.sh;
    executable = true;
  };

  xdg.configFile."joshuto/zathura.sh" = {
    source = ./zathura.sh;
    executable = true;
  };

  home.packages = with pkgs; [
    exiftool
    mediainfo
    fzf
  ];
}
