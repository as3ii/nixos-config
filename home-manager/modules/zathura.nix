{ ... }:

{
  programs.zathura = {
    enable = true;
    options = {
      window-title-home-tilde = true;
      guioptions = "shv";
      selection-clipboard = "clipboard";
    };
    mappings = {
      t = "toggle_statusbar";
      "[fullscreen] t" = "toggle_statusbar";
      f = "toggle_fullscreen";
      "[fullscreen] f" = "toggle_fullscreen";
    };
  };
}
