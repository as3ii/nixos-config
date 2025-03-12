{ config, ... }:

{
  programs.git = {
    enable = true;
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

  home.shellAliases = {
   gita = "git add";
   gotad = "git add -p";
   gitc = "git commit -S";
   gitd = "git diff";
   gitp = "git push";
   gits = "git status";
  };
}
