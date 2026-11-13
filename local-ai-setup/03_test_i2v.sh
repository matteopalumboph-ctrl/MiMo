#!/bin/bash
# =====================================================================
#  STEP 3 — Test reale Image-to-Video con Phosphene (LTX-2.5)
#  Misura: tempo totale, picco memoria/swap del sistema, rete durante il render.
#
#  Uso:  bash 03_test_i2v.sh "/percorso/foto.jpg" [quality]
#        quality: quick | balanced (default, consigliata su 16 GB) | standard
#  Prerequisito: Phosphene aperto, LTX-2.5 scaricato.
#  Per la prova "solo locale" definitiva: disattiva il Wi-Fi prima di lanciare.
# =====================================================================
set -u
IMG="${1:-}"; Q="${2:-balanced}"
ROOT="/Volumes/Extreme SSD/LOCAL_AI/phosphene"
TS=$(date +%Y%m%d_%H%M%S); OUT="$ROOT/tests/i2v_$TS"; mkdir -p "$OUT"
LOG="$OUT/metrics.txt"
[ -f "$IMG" ] || { echo "Uso: bash $0 /percorso/foto.jpg [quality]"; exit 1; }

# Trova la CLI di Phosphene (Mac app o Pinokio)
CLI=$(find "/Applications/Phosphene.app" "$HOME/Library/Application Support/Phosphene" \
           "$HOME/pinokio/api" "/Volumes/Extreme SSD/LOCAL_AI" -name phosphene_cli.py -path '*agents*' 2>/dev/null | head -1)
[ -n "$CLI" ] || { echo "phosphene_cli.py non trovato: Phosphene è installato e aperto?"; exit 1; }
PH() { python3 "$CLI" "$@"; }
PH status >/dev/null 2>&1 || { echo "Phosphene non risponde: apri l'app e riprova."; exit 1; }

PROMPT="Editorial fashion film. The model holds still, then slowly turns her head toward the light, \
a soft breath lifts her shoulders, loose strands of hair move in a faint breeze, fabric settles with real weight. \
Slow push-in, 50mm lens, shallow depth of field, soft window key light from camera left, natural skin texture, \
subtle film grain. Calm, intimate, no cuts."

WIFI=$(networksetup -getairportpower en0 2>/dev/null | awk '{print $NF}')
{
echo "Test I2V — $(date)"; echo "Immagine: $IMG"; echo "Quality: $Q  | Durata: 5 s"; echo "Wi-Fi: $WIFI"
echo "Swap prima: $(sysctl -n vm.swapusage)"
} | tee "$LOG"

# Campionamento memoria/swap/rete ogni 5 s in background
( PEAK_SWAP=0; while :; do
    FREE=$(memory_pressure 2>/dev/null | awk -F': ' '/free percentage/{print $2}')
    SW=$(sysctl -n vm.swapusage | awk '{gsub(/M/,"",$6); print $6}')
    NET=$(lsof -i -n -P 2>/dev/null | grep -i -E "python|phosph" | grep ESTABLISHED | grep -v -E "127\.0\.0\.1|\[::1\]|localhost" | awk '{print $9}' | sort -u | tr '\n' ' ')
    echo "$(date +%T) mem_free=$FREE swap_used=${SW}MB ext_conn=[${NET}]"
    sleep 5; done ) > "$OUT/samples.log" &
SAMPLER=$!

START=$(date +%s)
PH video "$PROMPT" --engine ltx --image "$IMG" --quality "$Q" --seconds 5 --seed 42 \
   --label "WEAREFRAMED_test_i2v" --out "$OUT" --timeout 7200
RC=$?
END=$(date +%s); kill $SAMPLER 2>/dev/null

MINFREE=$(awk -F'mem_free=' '{split($2,a,"%"); print a[1]}' "$OUT/samples.log" | sort -n | head -1)
MAXSWAP=$(awk -F'swap_used=' '{split($2,a,"MB"); print a[1]}' "$OUT/samples.log" | sort -n | tail -1)
EXT=$(grep -o 'ext_conn=\[[^]]\+\]' "$OUT/samples.log" | sort -u)
VID=$(find "$OUT" -name '*.mp4' | head -1)
{
echo "Esito CLI: $RC"
echo "Tempo totale: $(( (END-START)/60 )) min $(( (END-START)%60 )) s"
echo "Memoria libera minima di sistema: ${MINFREE}%"
echo "Swap massimo durante render: ${MAXSWAP} MB"
echo "Connessioni esterne di Phosphene durante render: ${EXT:-nessuna}"
[ -n "$VID" ] && { echo "Video: $VID"; mdls -name kMDItemPixelWidth -name kMDItemPixelHeight -name kMDItemDurationSeconds "$VID" 2>/dev/null; }
} | tee -a "$LOG"
echo; echo "Report: $LOG"
