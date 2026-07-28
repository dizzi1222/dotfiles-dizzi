#!/bin/bash
COMFY_DIR="$HOME/ComfyUI"
COMFY_PID_FILE="/tmp/comfyui.pid"
COMFY_PORT=8188

is_comfy_running() {
  if [ -f "$COMFY_PID_FILE" ]; then
    local pid=$(cat "$COMFY_PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then return 0; fi
    rm -f "$COMFY_PID_FILE"
  fi
  return 1
}

start_comfy() {
  cd "$COMFY_DIR" || { echo "❌ $COMFY_DIR no existe — clona primero: git clone https://github.com/comfyanonymous/ComfyUI ~/ComfyUI"; exit 1; }
  if [ ! -d venv ]; then
    echo "📦 Creando entorno virtual..."
    python3 -m venv venv
    source venv/bin/activate
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    pip install -r requirements.txt
  else
    source venv/bin/activate
  fi

  python main.py --cpu 2>/dev/null &
  echo $! >"$COMFY_PID_FILE"
  echo "🚀 ComfyUI iniciando en http://127.0.0.1:$COMFY_PORT"
  sleep 3
  xdg-open "http://127.0.0.1:$COMFY_PORT" 2>/dev/null
}

if is_comfy_running; then
  xdg-open "http://127.0.0.1:$COMFY_PORT" 2>/dev/null
else
  start_comfy
fi
wait
