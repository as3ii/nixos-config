{ config, lib, pkgs, ... }:

let
  cluster = config.cluster;

  proxiedServices = lib.filterAttrs (_: s: s.nodes != [ ] && s.expose == "proxy") cluster.services;
  proxyNames = builtins.attrNames (lib.filterAttrs (_: n: n.proxy) cluster.nodes);
  landingHosts = [ "proxy.${cluster.domain}" ] ++ (map (n: "${n}.${cluster.domain}") proxyNames);
  landingPageFile =
    if cluster.landingPage.file != null
    then pkgs.writeTextDir "index.html" (builtins.readFile cluster.landingPage.file)
    else
      pkgs.writeTextDir "index.html" ''
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <title>HomePage ${selfHostName}</title>
        </head>
        <body>
          <header>
            <h2>List of services</h2>
          </header>
          <main>
            <ul>
              ${
                let
                  scheme = if cluster.tls.mode == "disabled" then "http" else "https";
                in
                lib.concatStringsSep "\n" (
                  map (
                    svc: "<li><a href='${scheme}://${lib.head cluster.services.${svc}.vhost}.${cluster.domain}'>${svc}</a></li>"
                  ) (builtins.attrNames proxiedServices)
                )
              }
            </ul>
          </main>
          <footer>
            <p> as3ii - ${cluster.adminEmail} - &copy; 2026</p>
          </footer>
        </body>
        </html>
      '';

  sslStuff = [
    (lib.optionalAttrs (cluster.tls.mode == "acme") {
      forceSSL = true;
      useACMEHost = cluster.domain;
    })
    (lib.optionalAttrs (cluster.tls.mode == "manual") {
      forceSSL = true;
      sslCertificate = cluster.tls.certFile;
      sslCertificateKey = cluster.tls.keyFile;
    })
    (lib.optionalAttrs (cluster.tls.mode == "manual" && cluster.tls.chainFile != null) {
      sslTrustedCertificate = cluster.tls.chainFile;
    })
  ];

  authDirectUrl = "http://${cluster.nodes.${cluster.auth.node}.ipv4}:${toString cluster.auth.port}";
  authPortalUrl = "${if cluster.tls.mode == "disabled" then "http" else "https"}://${cluster.auth.vhost}.${cluster.domain}";
  authVirtualHost = lib.optionalAttrs (cluster.auth.enable && cluster.auth.node != "") {
    "${cluster.auth.vhost}.${cluster.domain}" = lib.mkMerge (
      [
        {
          locations."/" = {
            proxyPass = authDirectUrl;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        }
      ]
      ++ sslStuff
    );
  };
  mkUpstream = service: {
    servers = lib.listToAttrs (lib.concatMap
      (n: [{
        name = "${cluster.nodes.${n}.ipv4}:${toString service.port}";
        value = { };
      }] ++ lib.optional (cluster.nodes.${n}.ipv6 != null) {
        name = "[${cluster.nodes.${n}.ipv6}]:${toString service.port}";
        value = { };
      })
      service.nodes);
  };
  mkServiceVhost = name: service:
    let
      protected = cluster.auth.enable && service.auth != "none";
      authLocation = {
        "= /authelia" = {
          proxyPass = "${authDirectUrl}/api/authz/forward-auth?authelia_url=${authPortalUrl}";
          extraConfig = ''
            internal;
            proxy_pass_request_body off;
            proxy_set_header Content-Length "";
            proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
            proxy_set_header X-Original-Method $request_method;
          '';
        };
        "@error401" = {
          return = "302 ${authPortalUrl}/?rd=$scheme://$http_host$request_uri";
        };
      };
      root = {
        proxyPass = "${service.scheme}://${name}";
      } // lib.optionalAttrs protected {
        extraConfig = ''
          auth_request /authelia;
          auth_request_set $auth_user $upstream_http_remote_user;
          proxy_set_header Remote-User $auth_user;
        '';
      };
    in
    lib.mkMerge (
      [
        {
          locations = {
            "/" = root;
          } // lib.optionalAttrs protected authLocation;
        }
        (lib.optionalAttrs protected {
          extraConfig = "error_page 401 = @error401;";
        })
        ({
          serverAliases = map (v: "${v}.${cluster.domain}") (builtins.tail service.vhost);
        })
      ]
      ++ sslStuff
    );

  mkLandingVhost = lib.mkMerge (
    [
      {
        locations."/" =
          if cluster.landingPage.redirect != null
          then { return = "302 ${cluster.landingPage.redirect}"; }
          else { root = landingPageFile; index = "index.html"; };
      }
    ]
    ++ sslStuff
  );

  selfHostName = config.networking.hostName;
  selfNode = cluster.nodes.${selfHostName};
in
{
  imports = [ ../services/nginx.nix ];

  config = lib.mkIf (proxyNames != [ ]) {
    nginx = {
      enable = selfNode.proxy;
      #upstreams = lib.mapAttrs (service: (mkUpstream service)) proxiedServices;
      upstreams = lib.mapAttrs' (name: service: lib.nameValuePair (name) (mkUpstream service)) proxiedServices;
      virtualHosts =
        lib.mapAttrs'
          (name: service: lib.nameValuePair
            "${builtins.head service.vhost}.${cluster.domain}"
            (mkServiceVhost name service)
          )
          proxiedServices
        // authVirtualHost
        // lib.optionalAttrs cluster.landingPage.enable (lib.genAttrs landingHosts (_: mkLandingVhost));
    };
  };
}
