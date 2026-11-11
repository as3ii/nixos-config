{ mkClusterServiceOption, config, lib, ... }:

let
  # Reminder: list here only services exposed to the network
  serviceList = [
    # "beszel"
    # "forgejo"
    "gatus"
    # "graphana"
    # "opencloud"
    "pr-tracker"
    # "prometheus"
    "searx"
  ];
in
{
  imports = map (n: ../../services/${n}.nix) serviceList;

  options.cluster.services =
    lib.genAttrs (serviceList ++ lib.optional (config.bind.enable && config.bind.doh.enable) "doh") mkClusterServiceOption;

  config = lib.mkMerge (map
    (name:
      let
        svc = config.cluster.services.${name};
        host = config.networking.hostName;
      in
      (
        lib.mkIf (builtins.elem host svc.nodes) {
          ${name} = svc.otherOptions // {
            enable = true;
            port = svc.port;
          };
        }
      ))
    serviceList);
}
