default:
    just --list --unsorted | grep -v "  default"

### Checks

check *FLAGS:
    nix flake check --all-systems {{FLAGS}}

check-verbose: (check "-v")

### Updates

update:
    nix flake update

update-stable:
    nix flake update nixpkgs-stable

update-unstable:
    nix flake update nixpkgs-unstable

### Builds

build *FLAGS:
    nh os build {{FLAGS}}

build-trace: (build "--show-trace")

rpi3-image:
    #!/usr/bin/env sh
    printf "Are you sure you want to build a new image and rotate keys? (YES/no) "
    read -r resp
    if [ "$resp" != "YES" ]; then
        exit 0
    fi
    just age-keygen "rpi3"
    nom build .#rpi3-image || exit 1
    image="$(find result/sd-image/ -name "*.img")"
    # Remove file if it exists
    rm -f ./"${image##*/}"
    cp --no-preserve=all "$image" ./
    image="$(realpath "./${image##*/}")"
    # Install sops/age key
    function install_key() {
        loop="$(losetup --find --show --partscan "$image")"
        tmpdir="$(mktemp -d)"
        mount -v "${loop}p2" "$tmpdir"
        mkdir -pv "$tmpdir/var/lib/sops-nix"
        mv rpi3-age.txt "$tmpdir/var/lib/sops-nix/key.txt"
        chown root:root "$tmpdir/var/lib/sops-nix/key.txt"
        chmod 400 "$tmpdir/var/lib/sops-nix/key.txt"
        umount -v "$tmpdir"
        rmdir -v "$tmpdir"
        losetup -d "$loop"
    }
    sudo bash -c "$(declare -f install_key); image="$image"; install_key"
    echo "Image $image ready"

### Key handling

age-keygen name:
    #!/usr/bin/env sh
    set -eu
    if ! grep -q "secrets/{{name}}.yaml" .sops.yaml >/dev/null; then
        echo "secrets/{{name}}.yaml is not yet handled in .sops.yaml"
        exit 1
    fi
    # Remove file if it exists
    rm -f "{{name}}-age.txt"
    # Generate new key and save the public key
    age-keygen -o "{{name}}-age.txt" 2>/dev/null
    chmod 600 "{{name}}-age.txt"
    pubkey="$(sed -n -e "s/.*public key: //p" "{{name}}-age.txt")"
    if grep -q "&{{name}}" .sops.yaml >/dev/null; then
        # Substitute old key if it exists
        sed -i -e "/\&{{name}}/ s/ age.*/ $pubkey/" .sops.yaml
    else
        # Add the public key on sops config file, if key not found
        yq "
            .keys += (\"$pubkey\" | . anchor = \"{{name}}\") |
            (
                (.creation_rules[] | select(.path_regex == \"secrets/{{name}}.yaml\$\") |
                .key_groups[].age) += ((.keys[-1] | anchor) | . alias |= .)
            )
        " --indent 2 --inplace .sops.yaml
    fi
    just re-key
    echo "Now you should track the changes via git"

re-key:
    @find secrets/ -type f -exec sops updatekeys '{}' \;

# Deploy

deploy host *FLAGS:
    sops exec-file secrets/homelab/deploy-rs-key.enc "LOCAL_KEY={} deploy .#{{host}} {{FLAGS}}"
