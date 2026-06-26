# Call Library

Centralised list of all **container (Muezzin) calls** — the congregational frame voiced
*around* the salah, never inside it. Parallel to `prayers.md` (`P-` ids, in-salah recitation)
and the instruction library (`I-` ids, guidance). Reference a call in any container row using
its `call-id` (e.g. `C-2`).

Graduated from `../guided/CONGREGATIONAL-CONTAINER.md` §A (Container Call Library). The model,
placement rules, and fiqh rationale live there; this file is the **content source of truth**.

- **Code mirror:** `SalahMotion/Resources/calls.json` (data) + `SalahMotion/Core/Language/CallLibrary.swift`
  (loader). To add or edit a call, update `calls.json` only.
- **Binding policy (the fiqh boundary, in code):** a Muezzin voice/recording binds **only** to a
  `C-` id, never a `P-id`. A Muezzin recording for an in-salah `P-id` has nowhere to attach.
  The worshipper recites the salah; the Muezzin calls, commences, punctuates, and leads the
  dhikr *after*.
- **Voice:** every call is the **Muezzin**, voiced in Arabic. The transliteration + meaning are
  for the follower's display (du'ās permit own-language latitude — settled later).

## Fields

| field | meaning |
|---|---|
| `id` | `C-` call id |
| `name` | short label |
| `shape` | `call` (adhān/iqāma) · `boundary` (post-salām du'ā) · `dhikr` (post-salah remembrance) · `closing` (final supplication) |
| `count` | `0` = single utterance (listen) · `>0` = repeated dhikr at this count (tasbīḥ counter) |
| `verify` | `true` = Arabic still pending the user's review before voice-binding (Stage 3) |
| `arabic` · `transliteration` · `english` | voiced text · follower transliteration · meaning |

## Calls

| call-id | name | shape | count | meaning |
|---|---|---|---|---|
| `C-1` | Adhān | call | — | The call to prayer |
| `C-1F` | Adhān (Fajr) | call | — | …with *Aṣ-ṣalātu khayrun mina-n-nawm* ("prayer is better than sleep") — Fajr only |
| `C-2` | Iqāma | call | — | The prayer has begun (*Qad qāmati-ṣ-ṣalāh*) — opens the container, between sunnah and farḍ |
| `C-3` | Boundary du'ā | boundary | — | *Allāhumma anta-s-salām…* — **= `P-23`**, re-voiced by the Muezzin post-salām, after the **farḍ** |
| `C-4` | Istighfār | dhikr | ×3 | I seek the forgiveness of Allah |
| `C-5` | Āyat al-Kursī | dhikr | — | The Throne Verse (Qur'an 2:255) — included before the tasbīḥāt |
| `C-6` | Tasbīḥ | dhikr | ×33 | Glory be to Allah (*Subḥānallāh*) |
| `C-7` | Taḥmīd | dhikr | ×33 | All praise is for Allah (*Alḥamdulillāh*) |
| `C-8` | Takbīr | dhikr | ×33 | Allah is the Greatest (*Allāhu akbar*) |
| `C-9` | Tahlīl | dhikr | ×1 | *Lā ilāha illā-llāhu waḥdah…* — completes 100 |
| `C-10` | Ṣalawāt | dhikr | — | Blessings upon the Prophet ﷺ (*Allāhumma ṣalli ʿalā Muḥammad…*) |
| `C-11` | Closing du'ā | closing | — | Free supplication, hands raised — istighfār and asking acceptance; seals the session |

**Order of the post-salah seal (locked, see `../guided/container-sets/fajr.md`):**
istighfār → Āyat al-Kursī → 33 · 33 · 33 → tahlīl → ṣalawāt → closing du'ā.
**Count formula (locked, not a madhab axis):** 33 / 33 / 33 + 1 tahlīl = 100 (Muslim).

## Reuse (one source, not duplicated)

- `C-3` **is** `P-23` (same Arabic, byte-for-byte) — a *post-salah* act, so it lives honestly in
  the container; the in-salah `tasleem-left` `exit` hands it to the Muezzin.
- `C-10` Ṣalawāt reuses `P-9`'s Arabic byte-for-byte.
- `C-8` Takbīr is the same *phrase* as `P-0`, but re-vowelled to match the `C-6`/`C-7` dhikr
  trio's display style (so intentionally not byte-equal to `P-0`).

## Arabic verification (before Stage 3 voicing)

Nothing here is spoken in Stage 2 — it is content/display data only. The following carry
carefully-authored Arabic that **the user should verify before voice-binding**: `C-1`, `C-1F`,
`C-2`, `C-5`, `C-11` (`verify: true` in `calls.json`). `C-3 / C-8 / C-10` reuse Arabic verbatim
from `prayers.json`; the short dhikr (`C-4 / C-6 / C-7 / C-9`) are standard single phrases.
