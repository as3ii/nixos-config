{ config, lib, ... }:

let
  cluster = config.cluster;
  cfga = cluster.tls.acme;

  selfHostName = config.networking.hostName;
  selfNode = cluster.nodes.${selfHostName};
in
{
  config = lib.mkIf (cluster.tls.mode == "acme" && selfNode.proxy) {
    security.acme = {
      acceptTerms = true;
      certs.${cluster.domain} = {
        domain = "*.${cluster.domain}";
        email = cfga.email;
        server =
          if cfga.server == "le-staging" then "https://acme-staging-v02.api.letsencrypt.org/directory"
          else if cfga.server == "le-production" then "https://acme-v02.api.letsencrypt.org/directory"
          else throw "Invalid server option";
        keyType = cfga.keyType;
        profile = cfga.profile;
        dnsProvider = cfga.dnsProvider;
        dnsResolver = cfga.dnsResolver;
        extraDomainNames = cfga.extraDomainNames;
        environmentFile = cfga.environmentFile;
        reloadServices = cluster.tls.reloadServices; # nginx is automatically added
      };
    };
    users.users.nginx.extraGroups = [ "acme" ];
  };
}
