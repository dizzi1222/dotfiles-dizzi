#!/data/data/com.termux/files/usr/bin/sh
# Launcher de opencode (glibc bajo proot).
# Necesario para que Bun vea process.execPath = binario real y pueda spawnear
# "serve" para el background server; con el loader directo ese spawn falla 127.
unset LD_PRELOAD LD_LIBRARY_PATH
export SSL_CERT_FILE=/data/data/com.termux/files/usr/etc/tls/cert.pem
# Android/seccomp: sin esto proot se cuelga al arrancar opencode.
export PROOT_NO_SECCOMP=1
exec /data/data/com.termux/files/usr/bin/proot -r / \
  -b /data/data/com.termux/files/usr/glibc/lib:/lib \
  /data/data/com.termux/files/home/.local/share/core-termux-data/opencode/opencode "$@"
