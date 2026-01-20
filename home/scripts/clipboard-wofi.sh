#!/bin/bash
cliphist list | sort -rn | wofi --dmenu | cliphist decode | wl-copy
