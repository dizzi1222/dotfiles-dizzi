#!/usr/bin/env python3
"""Desbloquea el llavero Login existente con una contraseña recibida por stdin."""

import sys

try:
  import dbus
except ImportError:
  print("Falta python-dbus para desbloquear GNOME Keyring.", file=sys.stderr)
  sys.exit(1)


SERVICE_NAME = "org.freedesktop.secrets"
SERVICE_PATH = "/org/freedesktop/secrets"
COLLECTION_PATH = SERVICE_PATH + "/collection/login"
INTERNAL_INTERFACE = "org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface"
MAX_PASSWORD_BYTES = 8192


def read_password():
  """Lee bytes sin alterar espacios ni saltos de línea y rechaza entradas vacías."""
  password = sys.stdin.buffer.read(MAX_PASSWORD_BYTES + 1)
  if not password or len(password) > MAX_PASSWORD_BYTES or b"\0" in password:
    raise ValueError("La contraseña recibida tiene un formato no válido.")
  return password


def unlock_login(password):
  """Valida la contraseña y desbloquea Login mediante el daemon D-Bus existente."""
  bus = dbus.SessionBus(private=True)
  session = None
  try:
    service_object = bus.get_object(SERVICE_NAME, SERVICE_PATH, introspect=False)
    service = dbus.Interface(service_object, "org.freedesktop.Secret.Service")
    _, session_path = service.OpenSession(
      "plain", dbus.String("", variant_level=1), timeout=15
    )
    session = dbus.Interface(
      bus.get_object(SERVICE_NAME, session_path, introspect=False),
      "org.freedesktop.Secret.Session",
    )
    secret = dbus.Struct(
      (
        dbus.ObjectPath(session_path),
        dbus.ByteArray(b""),
        dbus.ByteArray(password),
        dbus.String("text/plain"),
      ),
      signature="oayays",
    )
    internal = dbus.Interface(service_object, INTERNAL_INTERFACE)
    internal.UnlockWithMasterPassword(
      dbus.ObjectPath(COLLECTION_PATH), secret, timeout=15
    )
    properties = dbus.Interface(
      bus.get_object(SERVICE_NAME, COLLECTION_PATH, introspect=False),
      "org.freedesktop.DBus.Properties",
    )
    if properties.Get("org.freedesktop.Secret.Collection", "Locked", timeout=15):
      raise RuntimeError("El llavero Login continúa bloqueado.")
  finally:
    if session is not None:
      try:
        session.Close(timeout=5)
      except dbus.DBusException:
        pass
    bus.close()


def main():
  """Devuelve un estado verificable sin escribir contraseñas ni detalles D-Bus."""
  try:
    password = read_password()
    unlock_login(password)
  except (ValueError, OSError, RuntimeError, dbus.DBusException):
    print(
      "No se pudo desbloquear Login; comprueba la contraseña y GNOME Keyring.",
      file=sys.stderr,
    )
    return 1
  print("Llavero Login desbloqueado.")
  return 0


if __name__ == "__main__":
  sys.exit(main())
