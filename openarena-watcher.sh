#!/bin/bash
# Tourne en root via systemd
# Surveille /tmp/joueur_attendu et dépose /tmp/openarena_go quand les deux joueurs sont prêts

SERVEUR_WEB="http://192.168.6.2"
FICHIER_ATTENDU="/tmp/joueur_attendu"
PI_ID="pi1"          # ← "pi2" sur le second Raspberry
INTERVAL=3

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a /var/log/openarena-watcher.log; }

log "=== Watcher démarré (PI_ID=$PI_ID) ==="

while true; do
    if [ ! -f "$FICHIER_ATTENDU" ]; then
        sleep $INTERVAL
        continue
    fi

    JOUEUR_ATTENDU=$(cat "$FICHIER_ATTENDU" | tr -d '[:space:]')
    if [ -z "$JOUEUR_ATTENDU" ]; then
        sleep $INTERVAL
        continue
    fi

    log "Joueur attendu : $JOUEUR_ATTENDU"

    # Attend que le joueur soit connecté à une session
    JOUEUR_CONNECTE=""
    while [ -z "$JOUEUR_CONNECTE" ]; do
        JOUEUR_CONNECTE=$(who | awk '{print $1}' | grep -ix "$JOUEUR_ATTENDU")
        if [ -z "$JOUEUR_CONNECTE" ]; then
            JOUEUR_CONNECTE=$(loginctl list-sessions --no-legend 2>/dev/null \
                | awk '{print $3}' | grep -ix "$JOUEUR_ATTENDU")
        fi
        [ -z "$JOUEUR_CONNECTE" ] && sleep $INTERVAL
    done

    log "✓ $JOUEUR_ATTENDU connecté — notification serveur..."

    curl -sf "${SERVEUR_WEB}/api/joueur_pret.php?joueur=${JOUEUR_ATTENDU}&pi=${PI_ID}" > /dev/null
    if [ $? -ne 0 ]; then
        log "ERREUR: impossible de contacter le serveur web"
        sleep $INTERVAL
        continue
    fi

    # Attend le GO (les deux joueurs prêts)
    STATUS=""
    while [ "$STATUS" != "GO" ]; do
        STATUS=$(curl -sf "${SERVEUR_WEB}/api/joueur_pret.php?status=1" 2>/dev/null)
        log "Status: $STATUS"
        [ "$STATUS" != "GO" ] && sleep $INTERVAL
    done

    log "▶ GO — dépôt du signal"
    touch /tmp/openarena_go

    # Attend que le fichier soit consommé par le launcher (ou timeout 60s)
    TIMEOUT=60
    while [ -f "/tmp/openarena_go" ] && [ $TIMEOUT -gt 0 ]; do
        sleep 2
        TIMEOUT=$((TIMEOUT - 2))
    done

    # Nettoyage
    rm -f "$FICHIER_ATTENDU"
    log "Cycle terminé, en attente du prochain match."

    sleep 2
done