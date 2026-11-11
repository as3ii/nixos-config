{ user, config, lib, pkgs, ... }:

{
  networking.hostName = "rpi3";

  boot.kernelPackages = pkgs.linuxPackages_6_18; # Force standard kernel, without rpi-specific drivers

  hardware.raspberry-pi = {
    firmware = {
      enable = true; # This requires a >60MB firmware partition, 80-100MB to be safe
      uboot.enable = true;
    };
    configtxt = {
      # Required for mainline kernel to work (eg. USB controller and ethernet)
      deviceTreeOverlays.pi3 = [
        { dwc2.dr_mode = "host"; }
      ];
      settings = {
        pi3.gpu_mem = 16; # Limit GPU VRAM to 16MB
      };
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/rpi3.yaml;
    defaultSopsFormat = "yaml";

    age = {
      keyFile = "/persistent/var/lib/sops-nix/key.txt";
      generateKey = false;
    };

    secrets = {
      "${user}-hashed-password" = { neededForUsers = true; };
      "tailscale-secret-key" = { };
    };
  };

  users.mutableUsers = false;

  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "tty" "dialout" "wheel" ];
    hashedPasswordFile = config.sops.secrets."${user}-hashed-password".path; # Generate with mkpasswd and then handle it with sops
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMOlCBxxZ1PVAUUQElno5SkZV0ui7DH4J9iJ4Shuzi6h nixos-as3ii" # pragma: allowlist secret
    ];
  };

  # Tailscale
  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--accept-routes"
      "--accept-dns"
      "--advertise-tags"
      "rpi,dns"
      "--ssh"
    ];
    authKeyFile = config.sops.secrets.tailscale-secret-key.path;
    authKeyParameters = {
      ephemeral = false;
      preauthorized = true;
    };
    openFirewall = true;
    serve = {
      enable = true;
      services = {
        ns2 = {
          endpoints = {
            "tcp:53" = "tcp://127.0.0.1:53";
            "tcp:80" = "http://127.0.0.1:80";
            "tcp:443" = "https://127.0.0.1:443";
          };
        };
      };
    };
  };
  # Add auto-restart, to handle the cases where it starts before time is synced
  # (rpi do not have RTC)
  systemd.services.tailscaled-autoconnect.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "30s";
  };

  # Wait of NTP sync before seeding (workaround for rpi not having RTC)
  systemd.services.bind.preStart = lib.mkBefore ''
    ${pkgs.coreutils}/bin/timeout 30 ${pkgs.bash}/bin/bash -c \
      'until [ "$(${config.systemd.package}/bin/timedatectl show -p NTPSynchronized --value)" = yes ]; do sleep 1; done' \
      || true
  '';

  services.fwupd.enable = false;

  # Read carefully NixOS changelogs before updating this.
  # See https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "26.11";
}
