{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # CLI tools
    unzip
    p7zip
    unrar
    compsize
    bat
    eza
    htop
    btop
    nmon
    exiftool
    mediainfo

    # Nix-specific tools
    nh # nix helper
    nix-output-monitor # nix wrapper, nice output
    nvd # nixos diff generations
  ];

  home.shellAliases = {
    grep = "grep --color=auto";
    ip = "ip -c";
    mv = "mv -i";
    rm = "rm -i";
    open = "xdg-open";
    cal = "cal -m -3";
    ssh = "TERM=xterm-256color ssh";

    cat = "bat";

    # eza aliases
    ls = "eza --classify";
    la = "eza --classify --all";
    ll = "eza --classify --group --long --header --git";
    tree = "eza --tree --level=4";
  };

  # enable direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.home-manager.enable = true;
}
