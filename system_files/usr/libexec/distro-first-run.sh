#!/bin/bash

# Cartella per i flag utente
FLAG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/distro-custom"
FLAG_FILE="$FLAG_DIR/first_run_completed"

# Se il file di flag esiste già, significa che la distro è già inizializzata.
# Avviamo DMS e usciamo.
if [ -f "$FLAG_FILE" ]; then
    echo "Distro già configurata. Avvio DMS in corso..."
    exec dms run
fi

# Creiamo la cartella per il flag se non esiste
mkdir -p "$FLAG_DIR"

echo "=== INIZIO INIZIALIZZAZIONE AMBIENTE NIRI + DMS ==="

# 1. Configurazione nativa di DMS per Niri
if command -v dms &> /dev/null; then
    echo "Esecuzione di dms setup pseudo niri..."
    # Questo comando genera i file strutturali in ~/.config/niri/ e integra DMS
    dms setup pseudo niri || true

    echo "Abilitazione del servizio utente Systemd per DMS..."
    # Abilita il demone utente nativo di DMS per i riavvii successivi
    systemctl --user enable --now dms || true

    # Controlla lo stato del servizio (come richiesto) per assicurarsi sia attivo
    echo "Verifica dello stato del servizio dms:"
    systemctl --user status dms --no-pager || true
fi

# 2. Inizializzazione di Docker Rootless
if command -v dockerd-rootless-setuptool.sh &> /dev/null; then
    echo "Configurazione Docker Rootless in corso..."
    dockerd-rootless-setuptool.sh install
    systemctl --user enable --now docker.service
fi

# 3. Generazione/Inizializzazione iniziale di Matugen (Temi e colori)
if command -v matugen &> /dev/null; then
    echo "Inizializzazione tavolozza colori Matugen..."
    matugen theme-initializer || true
fi

# 4. Creazione del file flag per evitare di rifare il setup pesante al prossimo boot
touch "$FLAG_FILE"
echo "=== DISTRO INIZIALIZZATA CON SUCCESSO ==="

# 5. Avvia la shell grafica per la sessione corrente rimpiazzando il processo dello script
exec dms run
