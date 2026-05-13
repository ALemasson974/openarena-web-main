#!/bin/bash
# Tourne dans la session graphique du joueur via autostart
# A accès naturellement au DISPLAY et XAUTHORITY sans configuration

SIGNAL_GO="/tmp/openarena_go"
FICHIER_ATTENDU="/tmp/joueur_attendu"
OPENARENA_BIN="/usr/bin/openarena"
SERVER_IP="192.168.6.2"

while true; do
    if [ -f "$FICHIER_ATTENDU" ] && [ -f "$SIGNAL_GO" ]; then
        JOUEUR_ATTENDU=$(cat "$FICHIER_ATTENDU" | tr -d '[:space:]')

        if [ "$JOUEUR_ATTENDU" = "$(whoami)" ]; then
            rm -f "$SIGNAL_GO"

            "$OPENARENA_BIN" +connect "$SERVER_IP" +set r_fullscreen 1 &
            OA_PID=$!

            # Garde le focus sur OpenArena tant qu'il tourne
            while kill -0 $OA_PID 2>/dev/null; do
                WID=$(xdotool search --name "OpenArena" 2>/dev/null | head -1)
                if [ -n "$WID" ]; then
                    ACTIVE=$(xdotool getactivewindow 2>/dev/null)
                    [ "$ACTIVE" != "$WID" ] && xdotool windowfocus --sync "$WID" windowraise "$WID"
                fi
                sleep 2
            done
        fi
    fi
    sleep 3
done