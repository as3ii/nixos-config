{ lib, pkgs, home-manager, sops-nix, ... }:

let
  user = "as3ii";
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/base.nix
      ../../modules/audio.nix
      ../../modules/bluetooth.nix
      ../../modules/podman.nix
      ../../modules/networking.nix
      ../../modules/libvirt.nix
      ../../modules/nvidia.nix
      ../../modules/waydroid.nix
      ../../modules/kernel-hardening.nix
      ../../modules/desktops/niri.nix
      #../../modules/desktops/plasma6.nix
      home-manager.nixosModules.home-manager
      sops-nix.nixosModules.sops
    ];

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
  #boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.kernelParams = [
    # Fix nvme power issues
    "nvme_core.default_ps_max_latency_us=1500"
    #"pcie_aspm=off"
    #"pcie_port_pm=off"
    # Fix amdgpu PSR causing glitches
    # "amdgpu.dcdebugmask=0x10" # Should be fixed: https://gitlab.freedesktop.org/drm/amd/-/work_items/4141#note_3613083
  ];

  # Hostname
  networking.hostName = "${user}-thinkpad-nixos";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  #hardware.amdgpu.opencl.enable = true;

  # Config for nvidia module
  nvidia.amdId = "PCI:198:0:0";
  nvidia.nvidiaId = "PCI:0:1:0";

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    excludePackages = with pkgs; [
      xterm
    ];
  };

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };
  console.useXkbConfig = true; # use xkb in tty

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "video" "audio" "input" "tty" "dialout" "plugdev" "networkmanager" "wheel" "libvirt" ];
    packages = with pkgs; [ ]; # switched to home-manager
    shell = pkgs.zsh;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    #extraSpecialArgs = { inherit (config) sops; };
    users = {
      ${user} = import ../../home-manager/${user}/home.nix;
    };
  };

  # Enable GUI support for Logitech Wireless Devices (solaar)
  hardware.logitech.wireless.enable = true;
  programs.solaar.enable = true;

  # Enable fingerprint reader support
  #services.fprintd.enable = true;
  #systemd.services.fprintd = {
  #  wantedBy = [ "multi-user.target" ];
  #  serviceConfig.Type = "simple";
  #};

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  #programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = lib.mkForce pkgs.pinentry-qt;
  };

  # enable binfmt registration to run appimages via appimage-run
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # List services that you want to enable:
  #services.espanso.enable = true; # shell/script vars types are broken

  # Thunderbolt
  services.hardware.bolt.enable = true;

  # RTL-SDR
  hardware.rtl-sdr.enable = true;

  services.flatpak.enable = true; # Enable flatpak
  xdg.portal.enable = true; # Enable xdg desktop portals

  # Tailscale
  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--accept-routes"
      "--accept-dns"
    ];
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Firewall configuration
  networking.firewall = {
    # Open TCP ports
    allowedTCPPorts = [
      22000 # syncthing: TCP based sync protocol traffic
    ];
    # Open UDP ports
    allowedUDPPorts = [
      22000 # syncthing: QUIC based sync protocol traffic
      21027 # syncthing: for discovery broadcasts on IPv4 and multicasts on IPv6
    ];
    # WireGuard settings (https://nixos.wiki/wiki/WireGuard#Setting_up_WireGuard_with_NetworkManager)
    extraCommands = ''
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
    '';
    extraStopCommands = ''
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
    '';
    logReversePathDrops = true;
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # Read carefully NixOS changelogs before updating this.
  # See https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "26.11";
}
