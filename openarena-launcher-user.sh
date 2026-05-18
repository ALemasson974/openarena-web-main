#!/bin/bash
SIGNAL_GO="/tmp/openarena_go"
SIGNAL_FIN="/tmp/openarena_fin"
FICHIER_ATTENDU="/tmp/joueur_attendu"
OPENARENA_BIN="/usr/bin/openarena"
SERVER_IP="192.168.6.2"
COMPTES_EXCLUS="root groupe1 r2 pi_admin administrator admin"

MOI=$(whoami)
if echo "$COMPTES_EXCLUS" | grep -qiw "$MOI"; then exit 0; fi

while true; do
    if [ -f "$FICHIER_ATTENDU" ] && [ -f "$SIGNAL_GO" ]; then
        JOUEUR_ATTENDU=$(cat "$FICHIER_ATTENDU" | tr -d '[:space:]')

        if [ "$JOUEUR_ATTENDU" = "$MOI" ]; then
            rm -f "$SIGNAL_GO"

            while [ ! -f "$SIGNAL_FIN" ]; do
                "$OPENARENA_BIN" +connect "$SERVER_IP" +set r_fullscreen 1 &
                OA_PID=$!

                while kill -0 $OA_PID 2>/dev/null; do
                    if [ -f "$SIGNAL_FIN" ]; then kill $OA_PID 2>/dev/null; break; fi
                    WID=$(xdotool search --name "OpenArena" 2>/dev/null | head -1)
                    if [ -n "$WID" ]; then
                        ACTIVE=$(xdotool getactivewindow 2>/dev/null)
                        [ "$ACTIVE" != "$WID" ] && xdotool windowfocus --sync "$WID" windowraise "$WID"
                    fi
                    sleep 2
                done

                [ ! -f "$SIGNAL_FIN" ] && sleep 3
            done

            rm -f "$SIGNAL_FIN" "$FICHIER_ATTENDU"
        fi
    fi
    sleep 3
done