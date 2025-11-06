# This wraps https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/networking/ssh/sshd.nix
{ config, lib, ... }:

let
  cfg = config.ssh;
in
{
  options.ssh = {
    ports = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ 22 ];
      description = ''
        Specifies on which ports the SSH daemon listens.
      '';
    };
    PermitRootLogin = lib.mkOption {
      default = "prohibit-password";
      type = lib.types.nullOr (
        lib.types.enum [
          "yes"
          "prohibit-password"
          "forced-commands-only"
          "no"
        ]
      );
      description = ''
        Whether the root user can login using ssh.
      '';
    };
    PasswordAuthentication = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = false;
      description = ''
        Specifies whether password authentication is allowed.
      '';
    };
    AllowUsers = lib.mkOption {
      type = with lib.types; nullOr (listOf str);
      default = null;
      description = ''
        If specified, login is allowed only for the listed users.
        See {manpage}`sshd_config(5)` for details.
      '';
    };
    DenyUsers = lib.mkOption {
      type = with lib.types; nullOr (listOf str);
      default = null;
      description = ''
        If specified, login is denied for all listed users. Takes
        precedence over [](#opt-services.openssh.settings.AllowUsers).
        See {manpage}`sshd_config(5)` for details.
      '';
    };
    AllowGroups = lib.mkOption {
      type = with lib.types; nullOr (listOf str);
      default = null;
      description = ''
        If specified, login is allowed only for users part of the
        listed groups.
        See {manpage}`sshd_config(5)` for details.
      '';
    };
    DenyGroups = lib.mkOption {
      type = with lib.types; nullOr (listOf str);
      default = null;
      description = ''
        If specified, login is denied for all users part of the listed
        groups. Takes precedence over
        [](#opt-services.openssh.settings.AllowGroups). See
        {manpage}`sshd_config(5)` for details.
      '';
    };
  };

  config = {
    services.openssh = {
      enable = true;
      ports = cfg.ports;
      # Log SFTP file access
      sftpFlags = [
        "-f AUTHPRIV"
        "-l INFO"
      ];
      settings = {
        X11Forwarding = false;
        PermitRootLogin = cfg.PermitRootLogin;
        PasswordAuthentication = cfg.PasswordAuthentication;
        GatewayPorts = "no";
        AllowUsers = cfg.AllowUsers;
        DenyUsers = cfg.DenyUsers;
        AllowGroups = cfg.AllowGroups;
        DenyGroups = cfg.DenyGroups;
      };
      extraConfig = ''
        # Explicit some default options
        PermitEmptyPasswords no
        IgnoreRhosts yes
        HostbasedAuthentication no
        PermitTunnel no
        TCPKeepAlive no
        LoginGraceTime 30
        MaxAuthTries 3
        MaxSessions 6
        MaxStartups 2
        # Disconnect unresponsive clients after 2 minutes
        ClientAliveCountMax 2
        ClientAliveInterval 60
      '';
    };
  };
}
