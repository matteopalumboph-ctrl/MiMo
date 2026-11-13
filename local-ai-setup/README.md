# WEAREFRAMED — Local AI Video Studio (MacBook Air M4 · 16 GB)

## Decisione

**Phosphene v5.0.20 (Mac app) + LTX-2.5, modelli su `/Volumes/Extreme SSD/LOCAL_AI/phosphene/models`.**
Repository: https://github.com/mrbizarro/phosphene · MIT

Perché:
- È il miglior I2V fotorealistico eseguibile su 16 GB oggi: LTX-2.5, ~5.7 GB di picco su 16 GB (v5.0.20).
- Upscale & Face Fix, Start/End frame e Motion Control in un'unica app; API locale e server MCP.
- La v5.0.20 supporta nativamente i modelli su disco esterno.

**Escluso MiniMax H3 (Hailuo).** È tecnicamente il migliore sui volti, ma la sua licenza **esclude l'UE, il Regno Unito, la Corea del Sud e gli USA**: non è utilizzabile per lavori clienti MPLURE dall'Italia. Inoltre pesa ~75 GB e su M4 Air sarebbe molto lento.

**Licenza LTX-2.x:** uso commerciale libero per entità con fatturato annuo **< 10 milioni USD**; sopra quella soglia serve una licenza a pagamento (`ltxv-licensing@lightricks.com`). Va rispettata la Acceptable Use Policy di Lightricks.

Alternativa di riserva: [dgrauet/ltx-2-mlx](https://github.com/dgrauet/ltx-2-mlx), una CLI con int8 `--low-ram`, HDR e multi-anchor, che usa gli stessi pesi LTX. Non va installata ora: sarebbe un duplicato.

## Procedura

**0. Inventario** (sola lettura):
```bash
bash inventory_mac_ai.sh
```

**1. Preflight + cartelle** sull'SSD. Il comando non installa nulla:
```bash
bash 01_prepare_ssd.sh
```

**2. Installazione** (manuale, ~5 min + download):
1. Scarica l'app da https://phosphene.video/download e trascinala in `/Applications`.
2. Al setup, alla voce sulla posizione dei modelli, scegli `/Volumes/Extreme SSD/LOCAL_AI/phosphene/models`.
3. Seleziona **solo LTX-2.5** (~27.5 GB). Non selezionare: Hailuo H3, musica, speech, Ideogram e FLUX.1 Krea. Questi ultimi due sono non commerciali.
4. Imposta la cartella output su `/Volumes/Extreme SSD/LOCAL_AI/phosphene/outputs`, se l'app lo permette in Settings.
5. Se Phosphene trova già modelli di una vecchia installazione Pinokio, li riusa: non riscaricarli.

**3. Test reale I2V.** Chiudi le altre app (Chrome e Adobe consumano molta RAM) e lancia:
```bash
bash 03_test_i2v.sh "/percorso/foto_modella.jpg" balanced
```
Per la prova definitiva di esecuzione solo locale: disattiva il Wi-Fi prima del render.
Lo script misura tempo, memoria minima, swap, connessioni esterne e risoluzione del video.
Il report viene salvato in `LOCAL_AI/phosphene/tests/i2v_<data>/metrics.txt`.

## Aspettative realistiche su M4 Air 16 GB
| Voce | Valore atteso |
|---|---|
| Risoluzione | ~480p in Balanced (768×448). Il full-size richiede 48 GB o più |
| Durata | 5 s (fino a ~10 s, con tempi più lunghi) |
| Tempo | ~10–11 min per 5 s (mediana di 36 M4 16 GB); l'Air senza ventola può rallentare su sessioni lunghe |
| Uso | Previsualizzazione, mood film, animatic, social. Per la consegna hero: Upscale & Face Fix oppure il render finale su una macchina ≥ 48 GB |

## Collegamento a Claude Code (opzionale)
```bash
claude mcp add phosphene -- python3 "<percorso>/agents/phosphene_mcp.py"
```
Il percorso esatto è indicato da `http://127.0.0.1:<porta>/agents/info` mentre l'app è aperta.
