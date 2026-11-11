{ user, config, ... }:

{
  networking.hostName = "trickster";

  boot.loader.systemd-boot = {
    enable = true;
    consoleMode = "auto";
    configurationLimit = 15;
  };

  hardware.graphics.enable = true;

  sops = {
    defaultSopsFile = ../../secrets/trickster.yaml;
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
      "nuc,dns"
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

  # Read carefully NixOS changelogs before updating this.
  # See https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "26.11";
}
