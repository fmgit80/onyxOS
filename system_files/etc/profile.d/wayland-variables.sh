#!/bin/bash
# Questo script viene eseguito automaticamente dal sistema ad ogni login utente

export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=niri
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland

# Configurazione per Docker Rootless
if [ -d "/run/user/$(id -u)" ]; then
    export DOCKER_HOST="unix:///run/user/$(id -u)/docker.sock"
fi
