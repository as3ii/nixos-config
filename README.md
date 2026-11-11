# My personal NixOS configuration files

Notes:

To protect usernames: `./secrets/homelab/authelia-users.yaml` is encrypted using
`sops encrypt --input-type binary --output-type binary $file` and should be
edited with `sops edit --input-type binary --output-type binary $file`
