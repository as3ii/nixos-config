# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
   #nixos-hardware = fetchTarball https://github.com/NixOS/nixos-hardware/archive/master.tar.gz;
   nixos-hardware = fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; };
in
{
  imports =
    [
      ./hardware-configuration.nix
      ./modules/base.nix
      ./modules/nixos-unstable.nix
      ./modules/audio.nix
      ./modules/bluetooth.nix
      ./modules/networking.nix
      #./modules/video-opengl.nix
      #./modules/nvidia-prime.nix
      "${nixos-hardware}/common/pc/ssd"
      "${nixos-hardware}/common/cpu/amd"
      "${nixos-hardware}/common/gpu/amd"
      "${nixos-hardware}/common/gpu/nvidia/prime.nix"
    ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    dynamicBoost.enable = true;
    prime = {
      # GPU Bus ID, converted from hex to decimal
      amdgpuBusId = "PCI:198:0:0";
      nvidiaBusId = "PCI:0:1:0";
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "auto";
  boot.loader.efi.canTouchEfiVariables = false;
  #boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackages_6_7;

  # Hostname
  networking.hostName = "as3ii-thinkpad-nixos";
  
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    excludePackages = with pkgs; [
      xterm
    ];
  };

  # Enable the Plasma 6 Desktop Environment.
  services.xserver.displayManager.sddm = {
    enable = true;
    autoNumlock = true;
    enableHidpi = true;
    settings = {
      General = { GreeterEnvironment = "QT_SCREEN_SCALE_FACTORS=2"; };
    };
  };
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs; [
    libsForQt5.elisa
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
    options = "eurosign:e ctrl:nocaps";
  };
  console.useXkbConfig = true; # use xkb in tty

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.as3ii = {
    isNormalUser = true;
    extraGroups = [ "video" "audio" "input" "tty" "networkmanager" "wheel" ];
    packages = with pkgs; [
      # CLI tools
      #xdotool
      #xsel
      wl-clipboard
      wtype
      eza
      bat
      fzf
      btop
      radeontop
      s-tui
      powertop
      pinentry
      unstable.rbw
      espanso-wayland
      mediainfo
      exiftool
      glxinfo
      vulkan-tools
      wayland-utils
      starship
      joshuto
      # GUI
      firefox
      alacritty
      (mpv.override { scripts = with mpvScripts; [ visualizer quality-menu mpris ]; })
      ff2mpv
      wofi
      rofi-rbw-wayland
      pinentry-qt
      qpwgraph
      kcc
      calibre
      telegram-desktop
      unstable.syncthing
      veracrypt
      zathura
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  #programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:
  #services.espanso.enable = true; # shell/script vars types are broken

  services.flatpak.enable = true;   # Enable flatpak
  xdg.portal.enable = true;         # Enable xdg desktop portals

  systemd.services.modem-manager.enable = false;

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}

