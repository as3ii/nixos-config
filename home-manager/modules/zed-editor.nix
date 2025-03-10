{ pkgs, ... }:

{
  programs.zed-editor = {
    enable = true;
    extensions = [ "nix" ];
    extraPackages = with pkgs; [
      #ruff
    ];
    userKeymaps = { };
    userSettings = {
      vim_mode = true;
      telemetry.metrics = false;
      ui_font_size = 16;
      buffer_font_size = 16;
      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };
    };
  };
}
