{ pkgs, ... }:

{
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
    # disabled because this only works for normal chromium
    #extensions = [
    #  { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # ublock origin light
    #  { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # dark reader
    #];
  };
}
