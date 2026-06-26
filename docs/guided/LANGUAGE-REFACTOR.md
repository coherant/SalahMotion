# Language Refactor — Parking Lot

**Status: PARKED.** Not scheduled. This is the deferred-design home for the
language / transliteration / TTS rework, sibling to `REFACTOR-PLAN.md` (the
observance arc). Captured 2026-06-26 from a design conversation so the findings
aren't lost. Nothing here is built yet.

> Same discipline as the observance refactor when we pick this up: **MD-first**,
> **golden-snapshot-protected**, small reversible stages. See `feedback_md_first`.

---

## The finding — the data model conflates two axes

Each prayer in `prayers.json` (mirror: `docs/prayers/prayers.md`) has three fields:

```json
{ "arabic": "اللهُ أَكْبَر", "turkish": "Allahu Ekber", "english": "Allah is the Greatest" }
```

These are treated as three peer "languages" (`Language` enum: `.english/.turkish/
.arabic`, codes `en/tr/ar`), but they are **not on the same axis**:

| field | what it actually is | axis |
|---|---|---|
| `arabic` | Arabic script | original / recitation |
| `turkish` | **transliteration** (Latin phonetics of the Arabic) | *pronunciation* |
| `english` | **meaning** (translation) | *understanding* |

`turkish` is a transliteration throughout — **not** Turkish meaning-words.

## How speech works today

On-device **TTS** (`AVSpeechSynthesizer`), no recordings. `PrayerStateMachine`
calls `audioManager.speak(prayer.utterance)`; `AudioManager.speak(text, language)`
speaks `text` with the voice `language.voiceCode`. Both the **text** (the field) and
the **voice** are chosen by the active `Language`:

| Language | text spoken (field) | voice (`voiceCode`) | net effect |
|---|---|---|---|
| English | `english` = **meaning** | `en-US` | **narrates the meaning**; you recite Arabic yourself (orb shows Arabic) |
| Turkish | `turkish` = **transliteration** | `tr-TR` | a Turkish voice reading the transliteration ≈ **recites the Arabic aloud** |
| Arabic | `arabic` = Arabic | `ar-SA` | actual Arabic recitation |

**The key asymmetry:** English mode *teaches the meaning*; Turkish mode *voices the
recitation*. They do fundamentally different jobs. The orb always shows Arabic; only
the spoken/secondary text differs.

## Why we are NOT just "translating" the Turkish

- **Religious constraint.** The Qur'anic recitation in salah (Al-Fatiha + surah) must
  be in **Arabic** — mainstream across all four madhabs incl. the relied-upon Hanafi
  view. Replacing the transliteration with Turkish meaning-words would guide an
  *invalid* recitation **and** delete the working spoken-recitation feature (the
  tr-TR-voice-reads-transliteration trick). Du'ās (Qunut, the closing As-Salām du'ā
  `P-23`) have more latitude and *may* be said in one's own language.
- So the transliteration is **load-bearing**, not a half-finished translation. Don't
  remove it; the real gap is that there is **no Turkish *meaning***, and **no
  recitation audio for English users** (English narrates meaning only).

## The core design fork (resolve before building)

`language` currently answers two different questions at once, inconsistently:

1. **What gets recited *to* me?** (Arabic — via `ar-SA` on the Arabic text, or via the
   `tr-TR` + transliteration trick)
2. **What language do I *understand* it in?** (English meaning / Turkish meaning)

Today English answers only #2, Turkish answers only #1 — **neither user gets both.**

**Recommended direction:** split the two axes.
- A **recitation layer** (UI-language-independent): `arabic` + `transliteration`,
  shown/voiced when it's time to recite. Prefer the `ar-SA` voice on the real Arabic
  for fidelity (see caveat) rather than leaning on transliteration.
- A **meaning layer** (per UI language): `english`, `turkish`, … for understanding.
- Let a user **hear the Arabic recited AND understand in their language**, rather than
  forcing one-or-the-other per `language`.

**Quality caveat:** approximating Arabic with a `tr-TR` voice on transliteration
mispronounces Arabic-only phonemes (ʿayn ع, ḥā ح, qāf ق, …). If recitation audio is a
goal, the Arabic field + `ar-SA` voice is the faithful source.

## Likely shape of the work when un-parked

- Rename the data field `turkish` → `transliteration`; **add a real `turkish`
  meaning** translation (and verify all existing translations — this absorbs the
  Stage-6 P-23 Arabic/Turkish translation-verification item).
- Rework `PrayerLibrary.text(...)` resolution and the **`Language` enum semantics**
  (separate "recitation source" from "meaning language").
- Decide UI: how the worshipper chooses recitation voice vs. understanding language.
- Snapshot impact: `GuidedSnapshotTests` keys on `language` — regenerate as a
  reviewed, intentional diff.

## Open questions for the user

- What should `language` mean: the language you **understand** in (recitation stays
  Arabic, separate), or literally "read me everything in this language"?
- Add a Turkish **meaning** (recommended, additive) vs. anything that touches the
  *recitation* text (advise against for salah; OK to consider for du'ās only)?
- Is recitation audio (hear the Arabic spoken) a feature we want for **all** users,
  not just the Turkish path?

## Superseded in large part by the Congregational Container

The `CONGREGATIONAL-CONTAINER.md` vision **largely dissolves this refactor.** Once the
Muezzin is out of the salah and in-salah recitation is shown as *text* (Arabic + meaning)
for the worshipper to recite — Silent Mode — there is no synthesizer pretending to recite,
which was the whole knot here. The axes land honestly: Adhān/Iqāma = Arabic (Muezzin);
in-salah = displayed (Arabic + meaning); dhikr / closing du'ā = Muezzin voice; guidance =
TTS in the user's language. Read that doc first; what (if anything) remains of this one is
small.

## Related

- **Congregational Container (the resolution): `CONGREGATIONAL-CONTAINER.md`.**
- Observance arc: `REFACTOR-PLAN.md`, `observances.md` (§5 per-unit niyet + surahs).
- Memory: `project_language_refactor`, `project_congregational_container`,
  `project_observance_refactor`, `feedback_md_first`.
