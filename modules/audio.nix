{ ... }:

{
  # Disable pulseaudio
  hardware.pulseaudio.enable = false;

  # Setup pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
}
