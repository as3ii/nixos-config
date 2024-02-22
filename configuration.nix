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

  hardware.nvidia.prime = {
    # GPU Bus ID, converted from hex to decimal
    amdgpuBusId = "PCI:198:0:0";
    nvidiaBusId = "PCI:0:1:0";
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "auto";
  boot.loader.efi.canTouchEfiVariables = false;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hostname
  networking.hostName = "nixos-as3ii";
  
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Plasma 5 Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

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
      firefox
      neovim
      alacritty
      (mpv.override { scripts = with mpvScripts; [ visualizer quality-menu mpris ]; })
      ff2mpv
      unstable.rbw
      xdotool
      xsel
      rofi
      rofi-rbw
      pinentry
      pinentry-qt
      telegram-desktop
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
  services.espanso.enable = true;

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

