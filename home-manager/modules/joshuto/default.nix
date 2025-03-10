{ pkgs, ... }:

{
  programs.joshuto = {
    enable = true;
    keymap = builtins.fromTOML (builtins.readFile ./joshuto.toml);
    mimetype = builtins.fromTOML (builtins.readFile ./mimetype.toml);
    settings = builtins.fromTOML (builtins.readFile ./joshuto.toml);
  };

  xdg.configFile."joshuto/preview_file.sh" = {
    source = ./preview_file.sh;
    executable = true;
  };

  home.packages = with pkgs; [
    exiftool
    mediainfo
    fzf
  ];
}
