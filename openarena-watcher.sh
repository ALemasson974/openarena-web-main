#!/bin/bash
FICHIER_ATTENDU="/tmp/joueur_attendu"
PI_ID="pi1"          # ← "pi2" sur le second Raspberry
INTERVAL=3
COMPTES_EXCLUS="root groupe1 r2 admin"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a /var/log/openarena-watcher.log; }

log "=== Watcher démarré (PI_ID=$PI_ID) ==="

while true; do
    if [ ! -f "$FICHIER_ATTENDU" ]; then sleep $INTERVAL; continue; fi

    JOUEUR_ATTENDU=$(cat "$FICHIER_ATTENDU" | tr -d '[:space:]')
    if [ -z "$JOUEUR_ATTENDU" ]; then sleep $INTERVAL; continue; fi

    log "Joueur attendu : $JOUEUR_ATTENDU"

    JOUEUR_CONNECTE=""
    while [ -z "$JOUEUR_CONNECTE" ]; do
        CONNECTES=$(who | awk '{print $1}')
        for USER in $CONNECTES; do
            if echo "$COMPTES_EXCLUS" | grep -qiw "$USER"; then continue; fi
            if echo "$USER" | grep -qix "$JOUEUR_ATTENDU"; then
                JOUEUR_CONNECTE="$USER"; break
            fi
        done
        [ -z "$JOUEUR_CONNECTE" ] && sleep $INTERVAL
    done

    log "✓ $JOUEUR_ATTENDU connecté — dépôt du signal GO"
    touch /tmp/openarena_go

    TIMEOUT=60
    while [ -f "/tmp/openarena_go" ] && [ $TIMEOUT -gt 0 ]; do
        sleep 2; TIMEOUT=$((TIMEOUT - 2))
    done

    rm -f "$FICHIER_ATTENDU"
    log "Cycle terminé."
    sleep 2
done