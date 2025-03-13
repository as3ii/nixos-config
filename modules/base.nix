{ lib, pkgs, ... }:

{
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  system = {
    #autoUpgrade = {
    #  enable = true;
    #  allowReboot = false;
    #  dates = "Sat";
    #};
  };

  # Mount a tmpfs on /tmp during boot
  boot.tmp.useTmpfs = true;

  # Set your time zone.
  time.timeZone = "Europe/Rome";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # Set reasonable date/time/currency/measurement format
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.UTF-8";
    LC_IDENTIFICATION = "en_IE.UTF-8";
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_IE.UTF-8";
    LC_NUMERIC = "en_IE.UTF-8";
    LC_PAPER = "en_IE.UTF-8";
    LC_TELEPHONE = "en_IE.UTF-8";
    LC_TIME = "en_IE.UTF-8";
  };
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    usbutils
    pciutils
    file
    inetutils
    dig
    htop
    bash-completion
    (neovim.override { vimAlias = true; viAlias = true; })
    smartmontools
    openssh
    openssl
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less";
    LESS = "-R";
    LESSHISTFILE = "-";
    HISTCONTROL = "ignorespace:erasedups";
    HISTSIZE = "100000";
  };

  systemd.extraConfig = lib.mkDefault ''
    DefaultTimeoutStopSec=60s
  '';
  systemd.user.extraConfig = lib.mkDefault ''
    DefaultTimeoutStopSec=60s
  '';

  # Fonts
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      font-awesome
      jetbrains-mono
      nerd-fonts.jetbrains-mono
    ];
    fontDir.enable = true;
  };

  # List services that you want to enable:

  # Firmware updates
  services.fwupd.enable = true;

  # use dbus-broker instead of the old dbus implementation
  services.dbus.implementation = "broker";
}

