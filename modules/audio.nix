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
    jack.enable = true;
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
