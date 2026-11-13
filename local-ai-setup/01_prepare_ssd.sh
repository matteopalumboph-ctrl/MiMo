#!/bin/bash
# =====================================================================
#  STEP 1 — Preflight + struttura cartelle su SSD per Phosphene
#  Non installa nulla, non usa sudo, non tocca file esistenti
#  (mkdir -p crea solo ciò che manca).
# =====================================================================
set -u
SSD="/Volumes/Extreme SSD"
ROOT="$SSD/LOCAL_AI"
P="$ROOT/phosphene"
ok(){ printf '  \033[32m✔\033[0m %s\n' "$1"; }
ko(){ printf '  \033[31m✘\033[0m %s\n' "$1"; FAIL=1; }
wa(){ printf '  \033[33m!\033[0m %s\n' "$1"; }
FAIL=0

echo "== Preflight"
[ "$(uname -m)" = "arm64" ] && ok "Apple Silicon ($(sysctl -n machdep.cpu.brand_string))" || ko "Non è Apple Silicon"
RAM=$(( $(sysctl -n hw.memsize) / 1073741824 )); ok "RAM ${RAM} GB"
ok "macOS $(sw_vers -productVersion)"

[ -d "$SSD" ] || { ko "SSD non montato: $SSD"; exit 1; }
FS=$(diskutil info "$SSD" | awk -F: '/File System Personality/{gsub(/^ +/,"",$2);print $2}')
case "$FS" in
  *APFS*) ok "File system SSD: $FS" ;;
  *ExFAT*|*exFAT*) wa "SSD in $FS: funziona per i modelli, ma niente permessi/symlink Unix e più rischio di corruzione se scollegato a caldo. Consigliato APFS (NON formatto nulla: decisione tua)." ;;
  *) wa "File system SSD: $FS — verificare compatibilità" ;;
esac
FREE=$(df -g "$SSD" | awk 'NR==2{print $4}')
[ "$FREE" -ge 60 ] && ok "Spazio libero SSD: ${FREE} GB (servono ~30 GB per LTX-2.5 + margine output)" || ko "Spazio libero SSD: ${FREE} GB — servono almeno 60 GB"
FREEI=$(df -g / | awk 'NR==2{print $4}')
[ "$FREEI" -ge 25 ] && ok "Spazio libero SSD interno: ${FREEI} GB (setup app ~18 GB)" || wa "SSD interno: ${FREEI} GB liberi — il setup ne chiede 18"
SWAP=$(sysctl -n vm.swapusage | awk '{print $6}'); echo "  · swap attuale: $SWAP"

echo; echo "== Cartelle"
for d in "$P/models" "$P/outputs" "$P/inputs" "$P/tests" "$ROOT/_reports"; do
  if [ -d "$d" ]; then ok "esiste già: $d"; else mkdir -p "$d" && ok "creata: $d"; fi
done

echo
[ "$FAIL" -eq 0 ] && echo "PRONTO. Procedi con lo STEP 2 (installazione app) della guida." || echo "Risolvi i punti ✘ prima di procedere."
