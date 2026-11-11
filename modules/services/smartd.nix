{ lib, config, pkgs, ... }:

let
  cfg = config.smartd;
  notification = pkgs.writeShellScript "smartd-notification.sh" ''
    ${lib.optionalString cfg.wall ''
      {
      ${pkgs.coreutils}/bin/cat << EOF
      Problem detected with disk: $SMARTD_DEVICESTRING
      Warning message from smartd is:

      $SMARTD_MESSAGE
      EOF
      } | ${pkgs.util-linux}/bin/wall 2>/dev/null
    ''}
    ${lib.optionalString cfg.user != null ''
      ${pkgs.systemd}/bin/systemd-run --machine=${cfg.user}@.host --user \
        ${pkgs.libnotify.out.outPath}/bin/notify-send "S.M.A.R.T. Error ($SMARTD_FAILTYPE)" \
        "$SMARTD_MESSAGE" --icon=dialog-warning -u critical
    ''}
  '';
in
{
  options.smartd = {
    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "your-user-name";
      description = ''
        Set the user that should receive smartd desktop notification.
      '';
    };
    wall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whenever to send wall notifications to all users.
      '';
    };
  };
  config = {
    services.smartd = {
      enable = true;
      autodetect = true;
      extraOptions = [
        "--interval=${3600 * 6}" # check status every 6 hours
      ];
      # avoid creation of any notification script, we use our own
      notifications = {
        mail.enable = lib.mkForce false;
        systembus-notify.enable = lib.mkForce false;
        wall.enable = lib.mkForce false;
        x11.enable = lib.mkForce false;
      };
      # -a = scan all parameters, equivalent of '-H -f -t -l error -l selftest -l selfteststs'
      # -o on = enable automatic offline testing
      # -n standby,8,q = skip disks in standby or sleep for max 8 times, don't log skips
      # -s (regex) = schedule short test on monday between 1-2am, long test on 1st and 15th day of month between 3-4am
      # -m <nomailer> -M exec ${script} = execute the specified script instead of calling the default mail command
      defaults.monitored = "-a -o on -n standby,8,q -s (S/../../1/01|L/../(01|15)/./03)"
        + lib.optionalString (cfg.user != null || cfg.wall) " -m <nomailer> -M exec ${notification}";
    };
  };
}
