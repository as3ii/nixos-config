{ ... }:

{
  # Disable pulseaudio
  services.pulseaudio.enable = false;

  # Setup pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true; # Deprecated. Use pkgs.pipewire.jack or pkgs.pr-jack to run specific apps that needs jack
    extraConfig = {
      # https://docs.pipewire.org/page_config.html
      # Monitor quantum and rate using `pw-top`
      pipewire = {
        "10-clock" = {
          "context.properties" = {
            "default.clock.allowed-rates" = [ 44100 48000 96000 192000 ];
            "default.clock.rate" = 96000; # Default: 48000
            "default.clock.quantum" = 512; # Default: 1024
            "default.clock.min-quantum" = 32; # Default: 32
            "default.clock.max-quantum" = 2048; # Default: 8192
          };
        };
        "10-rt" = {
          "context.modules" = [
            {
              "name" = "libpipewire-module-rt";
              "args" = {
                "nice.level" = -11;
                "rt.prio" = 88;
                "rt.time.soft" = 10000; # 10ms
                "rt.time.hard" = 10000; # 10ms
              };
              "flags" = [ "ifexists" "nofail" ];
            }
          ];
        };
      };
      jack = {
        "10-custom" = {
          "jack.properties" = {
            "rt.prio" = 80;
            "node.latency" = "512/48000"; # 10.6ms, default: 1024/48000 (21.3ms)
          };
        };
      };
      client = {
        "10-custom" = {
          "stream.properties" = {
            "node.latency" = "512/48000"; # 10.6ms, default: 1024/48000 (21.3ms)
            "resample.quality" = 8; # default: 4
          };
        };
      };
      pipewire-pulse = {
        "10-custom" = {
          "stream.properties" = {
            "node.latency" = "512/48000"; # 10.6ms, default: 1024/48000 (21.3ms)
            "resample.quality" = 8; # default: 4
          };
        };
      };
    };
  };
  # Increase limits
  security.pam.loginLimits = [
    {
      # Maximum locked-in-memory address space (KB)
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      # Maximum realtime priority
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "90";
    }
  ];
  # Allow set CPU DMA latency and kernel timers
  services.udev = {
    extraRules = ''
      KERNEL=="rtc0", GROUP="audio"
      KERNEL=="hpet", GROUP="audio"
      DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
    '';
  };
  # Enable threaded IRQs
  boot.kernelParams = [ "threadirqs" ];
}
