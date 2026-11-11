{ dns, config, lib, pkgs, ... }@inputs:

let
  cfg = config.bind-with-zones;
  writeZone = dns.util.${pkgs.stdenv.hostPlatform.system}.writeZone;
  plainZoneFiles = builtins.filter
    (
      name: lib.hasSuffix ".zone" name
    )
    cfg.zoneFiles;
  nixZoneFiles = builtins.filter
    (
      name: lib.hasSuffix ".zone.nix" name
    )
    cfg.zoneFiles;
  zoneSources = builtins.listToAttrs
    (map
      (fileName: {
        name = lib.removeSuffix ".zone" (builtins.baseNameOf fileName);
        value = fileName;
      })
      plainZoneFiles
    ) // builtins.listToAttrs
    (map
      (fileName:
        let
          name = lib.removeSuffix ".zone.nix" (builtins.baseNameOf fileName);
        in
        {
          name = name;
          value = writeZone name (import fileName inputs);
        }
      )
      nixZoneFiles
    );

  bindDir = config.services.bind.directory;

  zoneFilePath = name:
    if cfg.master
    then zoneSources.${name}
    else "${bindDir}/${name}.zone";

  seedScript = ''
    set -eu

    ${lib.concatMapStrings (name: ''
      zone=${lib.escapeShellArg name}
      generated=${lib.escapeShellArg (toString zoneSources.${name})}
      cache=${lib.escapeShellArg "${bindDir}/${name}.zone"}

      if [ ! -e "$cache" ]; then
        ${pkgs.coreutils}/bin/install -m 0644 "$generated" "$cache"
      else
        old=$(
          ${pkgs.bind}/bin/named-checkzone "$zone" "$cache" 2>/dev/null \
            | ${pkgs.gawk}/bin/awk '/loaded serial/ { print $NF }' \
            || true
        )

        new=$(
          ${pkgs.bind}/bin/named-checkzone "$zone" "$generated" \
            | ${pkgs.gawk}/bin/awk '/loaded serial/ { print $NF }'
        )

        if [ -z "$new" ]; then
          echo "bind-zone-seed: cannot read serial from $generated" >&2
          exit 1
        fi

        if [ -z "$old" ] || [ "$old" -lt "$new" ]; then
          ${pkgs.coreutils}/bin/install -m 0644 "$generated" "$cache"
        fi
      fi
    '') (builtins.attrNames zoneSources)}
  '';
in
{
  imports = [ ./bind.nix ];

  options.bind-with-zones = {
    enable = lib.mkEnableOption "Whether to enable `bind-with-zones`.";
    master = lib.mkOption {
      type = lib.types.bool;
      description = ''
        Master=false means this is a slave server.
      '';
    };
    slaves = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Addresses who may request zone transfers.";
      default = [ ];
    };
    masters = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of servers for inclusion in stub and secondary zones.";
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      description = "Extra zone config to be appended at the end of the zone section.";
      default = "";
      example = ''
        # Allow updates only from 192.168.0.0/24 and signed with example-tsig key
        allow-update { !{ !192.168.0.0/24; any; }; key example-tsig; };
      '';
    };
    zoneFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = ''
        Cluster zones files. Files with `.zone` extension are treated as standard
        static zone files (see https://bind9.readthedocs.io/en/v9.21.26/chapter3.html#zone-file).
        Files with `.zone.nix` extension are evaluated and converted to a file using `dns.util.writezone`.
      '';
      example = lib.literalExpression ''
        [
          ./path/to/fully.qualified.domain.zone
          ./path/to/second-fully.qualified.domain.zone.nix
        ]
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.master || builtins.length cfg.masters > 0;
        message = "Secondary DNS servers must have at least one primary DNS server";
      }
    ];

    bind.enable = true;
    bind.zones = builtins.mapAttrs
      (name: _source: {
        file = zoneFilePath name;
        master = cfg.master;
        masters = cfg.masters;
        slaves = cfg.slaves;
        extraConfig = cfg.extraConfig + lib.optionalString (!cfg.master) ''
          masterfile-format text;
        '';
      })
      zoneSources;

    systemd.services.bind = lib.mkIf (!cfg.master) {
      restartTriggers = builtins.attrValues zoneSources;
      preStart = lib.mkAfter seedScript;
    };
  };
}
