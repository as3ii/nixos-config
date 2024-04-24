# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ nixos-hardware, ...}:
{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./modules/base.nix
      ./modules/audio.nix
      ./modules/bluetooth.nix
      ./modules/container.nix
      ./modules/networking.nix
      nixos-hardware.nixosModules.common-pc-ssd
      nixos-hardware.nixosModules.common-cpu-amd
      nixos-hardware.nixosModules.common-gpu-amd
      nixos-hardware.nixosModules.common-gpu-nvidia
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

  hardware.trackpoint = {
    enable = true;
    emulateWheel = true;
  };

  # required for btrbk
  security.sudo = {
    enable = true;
    extraRules = [{
      commands = [
        {
          command = "${pkgs.coreutils-full}/bin/test";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.coreutils-full}/bin/readlink";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.btrfs-progs}/bin/btrfs";
          options = [ "NOPASSWD" ];
        }
      ];
      users = [ "btrbk" ];
    }];
    extraConfig = with pkgs; ''
      Defaults:picloud secure_path="${lib.makeBinPath [
        btrfs-progs coreutils-full
      ]}:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
    '';
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot = {
    enable = true;
    consoleMode = "auto";
    configurationLimit = 15;
  };
  boot.loader.efi.canTouchEfiVariables = false;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelPackages = pkgs.linuxPackages_6_7;

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
  services.displayManager.sddm = {
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

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.as3ii = {
    isNormalUser = true;
    extraGroups = [ "video" "audio" "input" "tty" "networkmanager" "wheel" ];
    packages = with pkgs; [
      # CLI tools
      unzip
      eza
      bat
      btop
      radeontop
      s-tui
      powertop
      glxinfo
      vulkan-tools
      wayland-utils
      starship
      podman
      podman-compose
      distrobox

      # Nix-specific tools
      nh                    # nix helper
      nix-output-monitor    # nix wrapper, nice output
      nvd                   # nixos diff generations

      # terminal file manager
      exiftool
      mediainfo
      fzf
      joshuto

      # Programming
      python3
      clang
      llvmPackages.bintools
      rustup
      go

      # rbw
      pinentry
      pinentry-qt
      unstable.rbw
      rofi-rbw-wayland

      # espanso
      #xdotool
      #xsel
      #espanso
      wl-clipboard
      ydotool
      espanso-wayland

      # Audio
      calf
      easyeffects
      qpwgraph
      spotify

      # GUI
      alacritty
      bleachbit
      discover
      ff2mpv
      (yt-dlp.override { withAlias = true; })
      (mpv.override { scripts = with mpvScripts; [ visualizer quality-menu mpris ]; })
      (firefox.override { nativeMessagingHosts = with pkgs; [ ff2mpv ]; })
      wofi
      kcc
      calibre
      handbrake
      discord
      telegram-desktop
      thunderbird
      kgpg
      unstable.syncthing
      unstable.steam
      unstable.steam-run
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
  programs.gnupg.agent.pinentryPackage = lib.mkForce pkgs.pinentry-qt;

  # enable direnv
  programs.direnv.enable = true;

  # List services that you want to enable:
  #services.espanso.enable = true; # shell/script vars types are broken

  services.flatpak.enable = true;   # Enable flatpak
  xdg.portal.enable = true;         # Enable xdg desktop portals

  # tailscale
  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--accept-routes"
      "--accept-dns"
    ];
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    22000   # syncthing: TCP based sync protocol traffic
  ];
  networking.firewall.allowedUDPPorts = [
    22000   # syncthing: QUIC based sync protocol traffic
    21027   # syncthing: for discovery broadcasts on IPv4 and multicasts on IPv6
  ];

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

# vim: sw=2
