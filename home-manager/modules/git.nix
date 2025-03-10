{ config, ... }:

{
  programs.git = {
    enable = true;
    aliases = {
      gita = "add";
      gotad = "add -p";
      gitc = "commit -S";
      gitd = "diff";
      gitp = "push";
      gits = "status";
    };
    attributes = [
      "* text=auto eol=lf"
    ];
    extraConfig = {
      init.defaultBranch = "master";
    };
    lfs.enable = true;

    #userName = "";
    #userEmail = "";
    signing = {
      #  key = "";
      signByDefault = config.programs.git.signing.key != null;
    };
  };
}
