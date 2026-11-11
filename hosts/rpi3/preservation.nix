{ user, ... }:

{
  imports = [ ../common/preservation.nix ];

  preservation.preserveAt."/persistent" = {
    users = {
      ${user} = {
        files = [ ];
        directories = [ ];
      };
    };
  };
}
