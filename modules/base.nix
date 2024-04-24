{ config, lib, pkgs, ... }:

{
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 25d";
    };
  };

  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = false;
      dates = "Sat";
      flags = ["-p" "unstable"];
    };
  };

  # Mount a tmpfs on /tmp during boot
  boot.tmp.useTmpfs = true;

  # Set your time zone.
  time.timeZone = "Europe/Rome";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # Set reasonable date/time/curency/measurement format
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
    dig
    git
    htop
    bash-completion
    (neovim.override { vimAlias = true; viAlias = true; })
  ];

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less";
    LESS = "-R";
    LESSHISTFILE = "-";
    HISTCONTROL = "ignorespace:erasedups";
    HISTSIZE = "10000";
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    font-awesome
    jetbrains-mono
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # List services that you want to enable:

  # Firmware updates
  services.fwupd.enable = true;

  # use dbus-broker instead of the old dbus implementation
  services.dbus.implementation = "broker";
}

