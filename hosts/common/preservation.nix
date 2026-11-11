{ lib, config, ... }:

let
  # Get dataDir from cluster services for this specific node, if the node is in the cluster
  hostName = config.networking.hostName;
  extraDirs = lib.optionals (config ? "cluster" && builtins.hasAttr hostName config.cluster.nodes)
    (lib.unique
      (lib.concatMap
        (name:
          if config.${name} ? preservationDirs
          then config.${name}.preservationDirs
          else lib.optional (config.${name} ? dataDir) config.${name}.dataDir
        )
        (lib.filter (name: config ? ${name})
          (lib.attrNames (lib.filterAttrs (_: svc: svc ? nodes && builtins.elem hostName svc.nodes) config.cluster.services))
        )
      )
    ++ lib.optional (config.cluster.auth.enable && config.cluster.auth.node == hostName) config.authelia.dataDir
    ++ lib.optional
      (config.cluster.tls.mode == "acme" && builtins.elem hostName (
        builtins.attrNames (lib.filterAttrs (_: n: n.proxy) config.cluster.nodes)
      ))
      config.security.acme.certs.${config.cluster.domain}.directory
    );
in
{
  fileSystems."/persistent".neededForBoot = true;

  preservation = {
    enable = true;

    preserveAt."/persistent" = {
      files = [
        { file = "/etc/machine-id"; inInitrd = true; how = "symlink"; configureParent = true; }
        { file = "/etc/ssh/ssh_host_ed25519_key"; how = "symlink"; configureParent = true; }
        { file = "/etc/ssh/ssh_host_ed25519_key.pub"; how = "symlink"; configureParent = true; }
        { file = "/etc/ssh/ssh_host_mldsa44_ed25519_key"; how = "symlink"; configureParent = true; }
        { file = "/etc/ssh/ssh_host_mldsa44_ed25519_key.pub"; how = "symlink"; configureParent = true; }
        { file = "/etc/ssh/ssh_host_rsa_key"; how = "symlink"; configureParent = true; }
        { file = "/etc/ssh/ssh_host_rsa_key.pub"; how = "symlink"; configureParent = true; }
      ];

      directories = [
        "/etc/nixos"
        #"/var/lib/NetworkManager"
        #"/var/lib/btrfs"
        #"/var/lib/cni"
        #"/var/lib/containers"
        #"/var/lib/libvirt"
        #"/var/lib/lxc"
        "/var/lib/nixos"
        "/var/lib/sops-nix"
        "/var/lib/systemd/timers"
        "/var/lib/tailscale"
        "/var/log"
      ] ++ extraDirs;

      # users = {
      #   root = {
      #     home = "/root";
      #     files = [];
      #     directories = [
      #       { directory = ".ssh"; mode = "0700"; }
      #     ];
      #   };
      # };
    };
  };

  # When the file does not exist yet, it is initialized with the string "uninitialized"
  # to satisfy the firstboot condition
  boot.initrd.systemd.tmpfiles.settings.preservation."/sysroot/persistent/etc/machine-id".f = {
    argument = "uninitialized";
  };
  # Adapt systemd-machine-id-commit.service to commit the transient ID to the persistent volume
  systemd.services.systemd-machine-id-commit = {
    unitConfig.ConditionPathIsMountPoint = [
      "/persistent/etc/machine-id"
    ];
    serviceConfig.ExecStart = [
      "systemd-machine-id-setup --commit --root /persistent"
    ];
  };
}
