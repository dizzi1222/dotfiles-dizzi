{ config, pkgs, ... }:

{
  # ── PipeWire (System Level) ────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Disable PulseAudio (PipeWire replaces it)
  services.pulseaudio.enable = false;

  # ── Audio packages ─────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    pavucontrol
    pamixer
    playerctl
    alsa-utils
    pulseaudio
    easyeffects
  ];
}
