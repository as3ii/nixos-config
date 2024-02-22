{ pkgs, ... }:

{
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    #extraPackages = with pkgs; [];
    #extraPackages32 = with pkgs.pkgsi686Linux; [];
  };
}
