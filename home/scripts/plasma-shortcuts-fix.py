#!/usr/bin/env python3
import re, sys, pathlib

p = pathlib.Path.home() / ".config/kglobalshortcutsrc"
p = p.resolve()
s = p.read_text(encoding="utf-8")

def setkey(text, key, value, section=None):
    # reemplaza la primera linea que empiece por key= (opcionalmente dentro de una seccion)
    lines = text.split("\n")
    sec = None
    for i, ln in enumerate(lines):
        m = re.match(r"^\[(.+)\]$", ln)
        if m:
            sec = m.group(1)
            continue
        if ln.startswith(key + "="):
            if section is None or sec == section:
                lines[i] = f"{key}={value}"
                return "\n".join(lines)
    return text

s = setkey(s, "Grid View", "none,none,Conmutar a la vista de cuadrícula")
s = setkey(s, "Overview", "Meta+O,Meta+O,Conmutar a la vista general")
s = setkey(s, "Window to Next Screen", "Ctrl+Shift+Period,Ctrl+Shift+Period,Mover ventana a la pantalla siguiente")
s = setkey(s, "Window to Previous Screen", "Ctrl+Shift+Comma,Ctrl+Shift+Comma,Mover ventana a la pantalla anterior")
s = setkey(s, "activate widget 26", "none,none,Activar el elemento gráfico Notificaciones")
s = setkey(s, "_launch", "Meta+Shift+Period", "services][net.local.glyphs.desktop")
s = setkey(s, "_launch", "Meta+Comma", "services][net.local.toggle-monitor.desktop")
s = setkey(s, "_launch", "Meta+Shift+B", "services][net.local.walset-menu.desktop")
s = setkey(s, "_launch", "Meta+N", "services][net.local.swaync.desktop")
s = setkey(s, "_launch", "Meta+Shift+N", "services][net.local.toggle-notifications.desktop")
s = setkey(s, "_launch", "Meta+Space", "services][net.local.vicinae.desktop")

p.write_text(s, encoding="utf-8")
print("escrito:", p)
