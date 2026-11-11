{ config, lib, ... }:

let
  cluster = config.cluster;

  selfHostName = config.networking.hostName;
in
{
  imports = [ ../services/authelia.nix ];

  config = lib.mkIf (cluster.auth.enable && selfHostName == cluster.auth.node) {
    authelia = {
      enable = true;
      port = cluster.auth.port;
      domain = cluster.domain;
      usersDB = config.sops.secrets.authelia_user_db.path;
      ACLs = [{
        domain = "${cluster.auth.vhost }.${cluster.domain}";
        policy = "bypass";
      }] ++ lib.concatMap (service: map (v: { domain = "${v}.${cluster.domain}"; policy = service.auth; }) service.vhost) (
        builtins.attrValues (lib.filterAttrs (_: s: s.nodes != [ ] && s.expose == "proxy" && s.auth != "none") cluster.services)
      );
      secrets = {
        jwtSecretFile = config.sops.secrets.authelia_jwt_secret.path;
        storageEncryptionKeyFile = config.sops.secrets.authelia_storage_encryption_key.path;
        sessionSecretFile = config.sops.secrets.authelia_session_secret.path;
      };
      metrics = false;
    };

    sops.secrets =
      let
        mkSecret = name: {
          format = "yaml";
          sopsFile = cluster.auth.sopsSecretsFile;
          key = name;
        };
      in
      {
        authelia_jwt_secret = mkSecret "authelia_jwt_secret";
        authelia_storage_encryption_key = mkSecret "authelia_storage_encryption_key";
        authelia_session_secret = mkSecret "authelia_session_secret";
        authelia_user_db = {
          format = "binary";
          sopsFile = cluster.auth.sopsUsersDBFile;
          owner = "authelia-main";
          group = "authelia-main";
        };
      };
  };
}
