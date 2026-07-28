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

    # ── RNNoise: supresión de ruido global (fuente virtual) ──
    # Crea un micrófono virtual "Noise Canceling source" que filtra el ruido de
    # fondo (teclado, ventilador, ambiente) con el modelo Xiph RNNoise. Sirve
    # para Meet, Discord, Zoom, etc.: seleccioná esa fuente en cada app.
    #
    # IMPORTANTE (PipeWire 1.6.3+, NixOS 26.11+): NO usar ruta absoluta en
    # plugin=; se referencia por nombre y la ruta se resuelve via LADSPA_PATH,
    # que solo setea el servicio si el paquete va en extraLadspaPackages (a
    # nivel NixOS; el de home-manager no funciona para el servicio).
    # Calidad: ★★ aceptable (voz algo 'robótica' con ruido fuerte). Para el
    # tier ★★★ ver options Khip / nvidia-voice-ai abajo.
    extraLadspaPackages = [ pkgs.rnnoise-plugin ];
    extraConfig.pipewire."99-input-denoising" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Noise Canceling source";
            "media.name" = "Noise Canceling source";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "librnnoise_ladspa";
                  label = "noise_suppressor_mono";
                  control = {
                    "VAD Threshold (%)" = 50.0;
                    "VAD Grace Period (ms)" = 200;
                    "Retroactive VAD Grace (ms)" = 0;
                  };
                }
              ];
            };
            "capture.props" = {
              "node.name" = "capture.rnnoise_source";
              "node.passive" = true;
              "audio.rate" = 48000;
            };
            "playback.props" = {
              "node.name" = "rnnoise_source";
              "media.class" = "Audio/Source";
              "audio.rate" = 48000;
            };
          };
        }
      ];
    };
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

  # ── UPGRADE DE CALIDAD (tier ★★★, opcional) ──────────────────
  # RNNoise es ★★. Si querés el tier Krisp hay 2 rutas en Linux:
  #
  # 1) KHIP (mismo modelo de Krisp que usa Discord, gratis y sin límite):
  #    - Obtenerlo: https://codeberg.org/khip/khip (build meson + FFTW3,
  #      libsamplerate, OpenBLAS). NO está en nixpkgs → necesita derivación
  #      Nix propia en nixos/pkgs/ (similar a sddm-astronaut-theme).
  #    - Luego: agregar khip a extraLadspaPackages y cambiar en el bloque de
  #      arriba `plugin = "librnnoise_ladspa"` por la .so de khip + label
  #      "khip_parent" (o la que de el build). Mismo esquema de filter-chain.
  #    - Calidad: ★★★ igual al Krisp propio, corre en GTX/CPU sin CUDA.
  #
  # 2) NVIDIA VOICE AI (esperimental, `nvidia-voice-ai` en GitHub — fork
  #    no oficial del RTX Voice para Linux):
  #    - Usa ONNX Runtime + la GPU NVIDIA (CUDA) → requiere `nvidia` driver +
  #      CUDA toolkit en NixOS (opt-in; pesado y frágil de mantener).
  #    - Ejecuta la IA como micrófono virtual vía loopback/filter-chain.
  #    - NO es el RTX Voice oficial (ese es Windows-only y exige GPU RTX;
  #      la GTX 1650 Mobile no lo soporta) — este port funciona con GTX.
  #    - Calidad: ★★★ comparable, pero setup largo → UE preferirlo SOLO si
  #      ya tenés CUDA por otro motivo.
  #
  # Regla práctica: RNNoise ya configurado = 90% del beneficio con 10% del
  # trabajo. Khip = el upgrade natural cuando sientas que RNNoise "suelena
  # robótico". nvidia-voice-ai = solo si el hardware NVIDIA ya se usa para
  # ML/CUDA en este mismo host.
}
