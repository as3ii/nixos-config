{ ... }:

{
  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = false; # Disable pulseaudio
  
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
