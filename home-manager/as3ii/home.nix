{ config, pkgs, sops-nix, ... }:

{
  imports = [
    sops-nix.homeManagerModules.sops
    ../modules/base.nix
    ../modules/git.nix
    ../modules/mpv.nix
    ../modules/rbw.nix
    ../modules/starship.nix
    ../modules/ungoogled-chromium.nix
    ../modules/zathura.nix
    ../modules/zed-editor.nix
    ../modules/zsh.nix
    ../modules/alacritty
    ../modules/espanso
    ../modules/joshuto
  ];

  home.packages = with pkgs; [
    # CLI tools
    radeontop
    s-tui
    powertop
    libva-utils
    glxinfo
    vulkan-tools
    wayland-utils
    starship
    distrobox
    ffmpeg_7-full

    cifs-utils

    # sops
    sops
    age

    # Programming
    rustup

    # Audio
    calf
    easyeffects
    qpwgraph
    spotify

    # spellcheck (required by libreoffice)
    hunspell
    hunspellDicts.it_IT
    hunspellDicts.en_US

    # GUI
    bleachbit
    (yt-dlp.override { withAlias = true; })
    (firefox.override { nativeMessagingHosts = with pkgs; [ ff2mpv ]; })
    wofi
    kcc
    calibre
    libreoffice-qt6-fresh
    heroic
    discord
    telegram-desktop
    thunderbird
    syncthing
    mangohud
    protonup-qt
    klog
    sdrangel
    unstable.steam
    unstable.steam-run
    veracrypt
  ];

  sops = {
    defaultSopsFile = ../../secrets/thinkpad-as3ii.yaml;
    defaultSopsFormat = "yaml";

    age = {
      keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      generateKey = false;
    };

    secrets = {
      rbw-email = { };
    };
  };

  home.file = { };

  home.sessionVariables = { };

  home.shellAliases = {
    scrub_start = "sudo btrfs scrub start";
    scrub_status = "sudo btrfs scrub status";
    defrag = "sudo btrfs filesystem defragment -rf -czstd";
    v = "nvim";
    clippy = "cargo clean; cargp fmt --all; cargo clippy -- -W clippy::pedantic";
  };

  fonts.fontconfig.enable = true;

  xdg.enable = true;

  xdg.desktopEntries.firefox-private = {
    name = "Firefox-private";
    genericName = "Web Browser";
    exec = "firefox --private-window %U";
    icon = "firefox";
    terminal = false;
    type = "Application";
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "text/xml" "x-scheme-handler/http" "x-scheme-handler/https" ];
  };

  git = {
    userName = "as3ii";
    userEmail = "as3ii777@gmail.com";
    signingKey = "6B8188396CF3EB82"; # pragma: allowlist secret
  };

  # this requires impure build, the email is stored in clear text in the nix store
  rbw.email = builtins.readFile config.sops.secrets.rbw-email.path;

  home.username = "as3ii";
  home.homeDirectory = "/home/as3ii";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.
}
