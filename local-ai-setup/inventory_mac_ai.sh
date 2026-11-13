#!/bin/bash
# =====================================================================
#  WEAREFRAMED / MPLURE — Inventario ambiente AI locale (SOLA LETTURA)
#  Target: MacBook Air M4 16 GB + SanDisk Extreme SSD
#
#  Cosa fa:   legge e misura. Scrive SOLO il file di report.
#  Cosa NON fa: nessun install, nessuna cancellazione, nessun sudo,
#               nessuna modifica a Ollama, Adobe o MisterHorse.
#
#  Uso:  bash inventory_mac_ai.sh
#  Output: /Volumes/Extreme SSD/LOCAL_AI/_reports/inventory_<data>.txt
# =====================================================================
set -u
SSD="/Volumes/Extreme SSD"
AIDIR="$SSD/LOCAL_AI"
TS=$(date +%Y%m%d_%H%M%S)
if [ -d "$AIDIR" ]; then
  mkdir -p "$AIDIR/_reports"
  OUT="$AIDIR/_reports/inventory_$TS.txt"
else
  OUT="$HOME/Desktop/inventory_ai_$TS.txt"
fi
# Percorsi esclusi dalla scansione (protetti)
EXCL='MisterHorse|Adobe|\.Trash|/Photos Library|/Music/'

h() { printf '\n==================== %s ====================\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
sz() { [ -e "$1" ] && du -sh "$1" 2>/dev/null | cut -f1 || echo "-"; }

{
echo "Inventario AI locale — $(date)"
echo "Report: $OUT"

h "SISTEMA"
sw_vers 2>/dev/null
echo "Chip:   $(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
echo "RAM:    $(( $(sysctl -n hw.memsize) / 1073741824 )) GB"
echo "GPU wired limit (MB): $(sysctl -n iogpu.wired_limit_mb 2>/dev/null || echo default)"
echo "Swap:   $(sysctl -n vm.swapusage 2>/dev/null)"
memory_pressure 2>/dev/null | tail -1

h "DISCHI"
df -h / "$SSD" 2>/dev/null
diskutil info "$SSD" 2>/dev/null | grep -E "File System Personality|Protocol|Solid State|Device Location"

h "HOMEBREW"
if have brew; then
  brew --version | head -1; echo "Prefix: $(brew --prefix)"
  echo "-- formule rilevanti:"; brew list --formula 2>/dev/null | grep -iE "python|ffmpeg|git-lfs|uv|pyenv|cmake|ollama|llama|mlx|node" | tr '\n' ' '; echo
  echo "-- cask rilevanti:";   brew list --cask 2>/dev/null | grep -iE "pinokio|ollama|lm-studio|diffusionbee|draw|comfy|phosphene|ltx" | tr '\n' ' '; echo
else echo "brew non installato"; fi

h "PYTHON / AMBIENTI"
for p in python3 python3.10 python3.11 python3.12 python3.13 uv pyenv conda mamba; do
  have "$p" && echo "$p -> $(command -v $p)  $($p --version 2>&1 | head -1)"
done
echo "-- pacchetti AI nel python3 di default:"
python3 -m pip list 2>/dev/null | grep -iE "^(mlx|torch|diffusers|transformers|accelerate|huggingface|safetensors|ltx|mlx-video|ltx-2-mlx)"
echo "-- virtualenv trovati (home + SSD, profondità 4):"
find "$HOME" "$AIDIR" -maxdepth 4 -name pyvenv.cfg 2>/dev/null | grep -vE "$EXCL" | while read -r f; do
  d=$(dirname "$f"); echo "$(sz "$d")  $d"; done

h "OLLAMA (solo lettura)"
if have ollama; then
  ollama --version 2>/dev/null; ollama list 2>/dev/null
else echo "ollama CLI non trovato"; fi
echo "OLLAMA_MODELS=${OLLAMA_MODELS:-<non impostato>}"
for d in "$HOME/.ollama/models" "$AIDIR/ollama" "$SSD/ollama"; do [ -d "$d" ] && echo "$(sz "$d")  $d"; done

h "MLX"
python3 -c "import mlx.core as mx; print('mlx', mx.__version__, '| device', mx.default_device())" 2>/dev/null || echo "mlx non importabile dal python3 di default"

h "APP E LAUNCHER AI"
for a in "/Applications/Phosphene.app" "/Applications/Pinokio.app" "/Applications/Ollama.app" \
         "/Applications/LM Studio.app" "/Applications/DiffusionBee.app" "/Applications/Draw Things.app" \
         "/Applications/ComfyUI.app" "/Applications/LTX Video.app" "/Applications/LTXVideo.app"; do
  [ -d "$a" ] && echo "$(defaults read "$a/Contents/Info" CFBundleShortVersionString 2>/dev/null)  $a"
done
echo "-- cartelle dati note:"
for d in "$HOME/pinokio" "$AIDIR/pinokio" "$SSD/pinokio" \
         "$HOME/Library/Application Support/Phosphene" "$HOME/phosphene" "$AIDIR/phosphene" \
         "$HOME/ComfyUI" "$AIDIR/ComfyUI" "$HOME/Documents/ComfyUI" \
         "$HOME/.cache/huggingface" "$AIDIR/huggingface" "$HOME/.lmstudio" \
         "$HOME/Library/Containers/com.liuliu.draw-things/Data/Documents/Models" \
         "$HOME/.diffusionbee"; do
  [ -e "$d" ] && echo "$(sz "$d")  $d"
done
[ -d "$HOME/pinokio/api" ]  && { echo "-- app Pinokio (home):"; ls -1 "$HOME/pinokio/api"; }
[ -d "$AIDIR/pinokio/api" ] && { echo "-- app Pinokio (SSD):";  ls -1 "$AIDIR/pinokio/api"; }
echo "HF_HOME=${HF_HOME:-<non impostato>}  HF_HUB_CACHE=${HF_HUB_CACHE:-<non impostato>}"

h "CACHE HUGGING FACE — repo scaricati"
for c in "${HF_HUB_CACHE:-}" "${HF_HOME:-}/hub" "$HOME/.cache/huggingface/hub" "$AIDIR/huggingface/hub"; do
  [ -n "$c" ] && [ -d "$c" ] && { echo "-- $c"; for m in "$c"/models--*; do [ -d "$m" ] && echo "$(sz "$m")  $(basename "$m" | sed 's/^models--//; s/--/\//')"; done; }
done

h "CONTENUTO /Volumes/Extreme SSD/LOCAL_AI (livello 1-2)"
[ -d "$AIDIR" ] && find "$AIDIR" -maxdepth 2 -mindepth 1 2>/dev/null | while read -r d; do echo "$(sz "$d")  $d"; done | sort -k2

h "FILE MODELLO > 500 MB (safetensors/gguf/ckpt/pt/bin/npz)"
TMPL=$(mktemp)
find "$HOME" "$SSD" -xdev \( -iname '*.safetensors' -o -iname '*.gguf' -o -iname '*.ckpt' \
     -o -iname '*.pt' -o -iname '*.pth' -o -iname '*.bin' -o -iname '*.npz' \) -size +500M 2>/dev/null \
  | grep -vE "$EXCL" | while read -r f; do
      s=$(stat -f %z "$f" 2>/dev/null); echo "$s|$(basename "$f")|$f"; done > "$TMPL"
sort -t'|' -k1,1nr "$TMPL" | awk -F'|' '{printf "%7.2f GB  %s\n", $1/1073741824, $3}'
echo; echo "Totale: $(awk -F'|' '{t+=$1} END{printf "%.1f GB", t/1073741824}' "$TMPL") in $(wc -l < "$TMPL" | tr -d ' ') file"

h "POSSIBILI DUPLICATI (stesso nome + stessa dimensione) — NIENTE VIENE CANCELLATO"
awk -F'|' '{k=$1"|"$2; c[k]++; p[k]=p[k]"\n      "$3} END{for(k in c) if(c[k]>1){split(k,a,"|"); printf "%.2f GB x%d  %s%s\n", a[1]/1073741824, c[k], a[2], p[k]}}' "$TMPL"
echo "(nota: i blob Ollama/HF possono essere hardlink o symlink: verificare prima di qualsiasi pulizia)"
rm -f "$TMPL"

h "INSTALLAZIONI INCOMPLETE (download parziali)"
find "$HOME" "$SSD" -xdev \( -name '*.incomplete' -o -name '*.part' -o -name '*.partial' -o -name '*.download' \) -size +10M 2>/dev/null \
  | grep -vE "$EXCL" | while read -r f; do echo "$(sz "$f")  $f"; done

echo; echo "FINE INVENTARIO — nessun file è stato modificato o cancellato."
} 2>&1 | tee "$OUT"
