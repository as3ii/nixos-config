# My personal NixOS configuration files

### Cluster/homelab

The main configuration file is `inventories/homelab/default.nix`. Here are defined
IPs, services, TLS, DNS, cluster-wide secrets, etc.
Remember to update `cluster.serial` when changing exposed services, node names,
IP addresses or a DNS zone.

When adding a new network exposed service in `modules/services`, to expose it in
the cluster config you should add the service name in the array at the top of
`modules/cluster/services/default.nix`, after that you can customize the service
in the cluster inventory file setting the options: nodes, port, scheme, expose
and auth, other options can be placed inside the attrSet `otherOptions`.

To deploy changes to the nodes you can use `just deploy ${node}`, optionally with
the `--boot` option if you want the change to be available only after a reboot.

DON'T run `just rpi3-image` if you want to keep using the current rpi3: that
command will rotate rpi3 keys and inject the new key in the image, so the old
rpi3 will not be able to decrypt secrets and stop working if you run
`just deploy rpi3` without actually flashing the new image onto the rpi3's SD.

### Secrets handling

#### Add a new key

To add a new key:
- you can use `age-keygen -o "${keyname}-age.txt"` or derive the key from a GPG or SSH key
- open `.sops.yaml`, add the key in the top array, and add the key anchor to the
  right `creation_rules` entry
- then run `just re-key` to update the secrets files that need to be updated

Or, you can add an entry in `creation_rules` in `.sops.yaml` matching
`secrets/${name}.yaml` and then use `just age-keygen ${name}` with the key name.

NEVER commit the file `${keyname}-age.txt`.

#### Change an encrypted secret

Run `sops edit secrets/${file}` with the correct file name and path.
Files with `.enc` extension are encrypted as if they were binary files.
Files with `.yaml` extension have only encrypted values (yaml keys are in clear text).

#### Sops key placement

To know where the key is expected to be installed, refer to the `sops` attrSet in
the various `hosts/${name}/configuration.nix` and `home-manager/${user}/home.nix`.
