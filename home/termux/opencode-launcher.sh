#!/data/data/com.termux/files/usr/bin/sh
# Launcher de opencode.
# proot 5.1.107.97 segfaulta al crear instancias nuevas en este Android,
# así que ejecutamos el binario glibc directamente. Bun resuelve el loader
# y el spawn de "serve" funciona con process.execPath = binario real.
unset LD_PRELOAD LD_LIBRARY_PATH
export SSL_CERT_FILE=/data/data/com.termux/files/usr/etc/tls/cert.pem
exec /data/data/com.termux/files/home/.local/share/core-termux-data/opencode/opencode "$@"
