#!/usr/bin/env python3
"""Generate docs/audio-coverage.md — the audio recording brief — from the master files.

Master sources (single source of truth):
  SalahMotion/Resources/calls.json          (C — Muezzin calls)
  SalahMotion/Resources/instructions.json   (I — guidance)
  SalahMotion/Resources/prayers.json        (P — recitation ids)
Plus a scan of SalahMotion/Resources(/recitations|/muezzin) for installed audio.

Usage:   python3 scripts/generate_audio_coverage.py
Rule:    edit the master JSONs, never the generated doc; then re-run.
"""
import json, os, glob, datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES  = os.path.join(ROOT, "SalahMotion", "Resources")
OUT  = os.path.join(ROOT, "docs", "audio-coverage.md")

RECITER = "muallim-ai"       # reciter voice → recitation (P)   (Muʿallim AI)
MUEZZIN = "munadi-ai"        # muezzin voice → calls (C)        (Munādī AI)
GUIDER  = "murshid-ai"       # guider voice → guidance (I)      (Murshid AI)
LANGS   = ["ar", "en", "tr"] # active recitation languages
EXTS    = ("m4a", "caf")
FORMAT  = "AAC `.m4a`, mono, 24 kHz, ~64 kbps"

def installed(stem: str) -> bool:
    for sub in ("", "recitations", "muezzin"):
        for ext in EXTS:
            if os.path.exists(os.path.join(RES, sub, f"{stem}.{ext}")):
                return True
    return False

def load(name): return json.load(open(os.path.join(RES, name), encoding="utf-8"))

calls   = load("calls.json")["calls"]
ins     = load("instructions.json")["instructions"]
prayers = load("prayers.json")["prayers"]

# Coverage
p_ids = [p["id"] for p in prayers]
p_missing = {l: [pid for pid in p_ids if not installed(f"{RECITER}-{l}-{pid}")] for l in LANGS}
p_total, p_have = len(p_ids) * len(LANGS), sum(len(p_ids) - len(p_missing[l]) for l in LANGS)
i_ids = [e["id"] for e in ins]
i_missing = {l: [iid for iid in i_ids if not installed(f"{GUIDER}-{l}-{iid}")] for l in LANGS}
i_total, i_have = len(i_ids) * len(LANGS), sum(len(i_ids) - len(i_missing[l]) for l in LANGS)
for c in calls:
    c["file"] = f"{MUEZZIN}-{c['id']}.m4a"
    c["recorded"] = installed(f"{MUEZZIN}-{c['id']}")
c_have = sum(1 for c in calls if c["recorded"])

L = []
add = L.append
add("# Audio coverage & recording brief — P / I / C\n")
add(f"> **GENERATED** by `scripts/generate_audio_coverage.py` — do not edit by hand.\n"
    f"> Edit the master files (`calls.json`, `instructions.json`, `prayers.json`) and re-run.\n"
    f"> Snapshot: **{datetime.date.today().isoformat()}**\n")
add("## Conventions\n"
    f"- **Recitation (P):** `{RECITER}-<lang>-<P-id>.m4a` — languages: {', '.join(LANGS)}\n"
    f"- **Muezzin call (C):** `{MUEZZIN}-<C-id>.m4a` — **Arabic only**\n"
    f"- **Guidance (I):** `{GUIDER}-<lang>-<I-id>.m4a` — languages: {', '.join(LANGS)}\n"
    f"- **Format:** {FORMAT}\n")
add("## Summary\n")
add("| Family | ids | recorded | outstanding |")
add("|---|---|---|---|")
add(f"| P — recitation | {len(p_ids)} (×{len(LANGS)} = {p_total}) | {p_have} | {p_total - p_have} |")
add(f"| C — Muezzin calls | {len(calls)} | {c_have} | {len(calls) - c_have} |")
add(f"| I — guidance | {len(i_ids)} (×{len(LANGS)} = {i_total}) | {i_have} | {i_total - i_have} |\n")

add(f"## C — Muezzin calls (record in Arabic → `{MUEZZIN}-<id>.m4a`)\n")
add("| id | name | file | recorded? |")
add("|---|---|---|---|")
for c in calls:
    add(f"| {c['id']} | {c['name']} | `{c['file']}` | {'✅' if c['recorded'] else '❌'} |")
add("\n### Text to record (Arabic) — with transliteration & meaning\n")
for c in calls:
    add(f"**{c['id']} · {c['name']}** — `{c['file']}`  ")
    add(f"- AR: {c['arabic']}  ")
    add(f"- Pronounce: {c.get('transliteration','')}  ")
    add(f"- Meaning: {c.get('english','')}\n")

add(f"## P — recitation (reciter: `{RECITER}`)\n")
for l in LANGS:
    miss = p_missing[l]
    add(f"- **{l}**: {len(p_ids) - len(miss)}/{len(p_ids)} "
        + ("✅" if not miss else f"— missing: {', '.join(miss)}"))
add("\n> Parked (recordings exist in source, not imported): German, Turkish-transliteration.\n")

add(f"## I — guidance (record per language → `{GUIDER}-<lang>-<I-id>.m4a`)\n")
for l in LANGS:
    miss = i_missing[l]
    add(f"- **{l}**: {len(i_ids) - len(miss)}/{len(i_ids)} "
        + ("✅" if not miss else f"— missing: {', '.join(miss)}"))
add("\n> Parked (text only, not a supported `Language`): German.\n")
add("### Text to record — English · Arabic · Türkçe (· Deutsch parked)\n")
add("| id | English | Arabic | Türkçe | Deutsch |")
add("|---|---|---|---|---|")
for e in ins:
    add(f"| {e['id']} | {e['instruction']} | {e.get('arabic','')} | "
        f"{e.get('turkish','')} | {e.get('german','')} |")
add("")

with open(OUT, "w", encoding="utf-8") as f:
    f.write("\n".join(L))
print("wrote", os.path.relpath(OUT, ROOT))
print(f"P {p_have}/{p_total} | C {c_have}/{len(calls)} | I {i_have}/{i_total}")
