{ config, pkgs, ... }:

let
  mpv-hdr = pkgs.writeShellScriptBin "mpv-hdr" ''
    ENABLE_HDR_WSI=1 ${config.programs.mpv.finalPackage.outPath}/bin/mpv \
       --vo=gpu-next --target-colorspace-hint \
       --gpu-api=vulkan --gpu-context=waylandvk \
       "$@"
  '';
in
{
  programs.mpv = {
    enable = true;
    bindings = {
      i = "script-binding stats/display-stats-toggle";
      y = "script-binding quality_menu/video_formats_toggle";
      Y = "script-binding quality_menu/audio_formats_toggle";
      "[" = "add speed -0.1";
      "]" = "add speed 0.1";
      "{" = "add speed -1";
      "}" = "add speed 1";
    };
    config = {
      profile = "gpu-hq";
      hwdec = "auto-safe";
      vo = "gpu";
    };
    scripts = with pkgs.mpvScripts; [
      visualizer
      quality-menu
      mpris
    ];
    scriptOpts = { };
  };

  home.packages = [ mpv-hdr ];
}
