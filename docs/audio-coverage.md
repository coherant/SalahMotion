# Audio coverage — P / I / C

Which liturgical ids have a recorded audio file vs fall back to TTS. Generated
from the source of truth: `Resources/recitations/`, `Resources/instructions.json`,
`Resources/calls.json`. Snapshot: **2026-06-29** (branch `worktree-audio-enablement`).

## How audio resolves (current)
- **Recitation (P):** `recitations/<reciterId>-<language>-<P-id>.m4a` (flat, unique
  names; resolver searches bundle root + `recitations/`; `.m4a` or `.caf`).
  Active reciter = **Ṣawt AI** (`sawt-ai`), AI-generated. Active languages: `ar`,`en`,`tr`.
- **Muezzin call (C):** `muezzin/<muezzinId>-<C-id>.m4a` — *none installed yet.*
- **Guidance (I):** **TTS-only by design** (English) — never a recorded clip today.
- Missing clip → silent **TTS fallback** (`AudioClips` / `PrayerStateMachine.utter`).

## Summary
| Family | Total | Have audio | Missing |
|---|---|---|---|
| **P** — recitation | 24 | 24 (ar/en/tr) | **0** ✅ |
| **C** — Muezzin calls | 12 | 0 | **12** |
| **I** — guidance | 52 | 0 | **52** (by design) |

- **P:** complete for ar/en/tr. Parked: German + Turkish-transliteration recordings.
- **C:** the real recording gap (record → `muezzin/<muezzinId>-C-N.m4a`).
- **I:** intentionally TTS; record only if voiced guidance is wanted (needs an `I-`
  resolver path — TTS-only today).

## C — Muezzin calls (no audio)
| id | Call |
|---|---|
| C-1 | Adhān |
| C-1F | Adhān (Fajr) |
| C-2 | Iqāma |
| C-3 | Boundary du'ā |
| C-4 | Istighfār |
| C-5 | Āyat al-Kursī |
| C-6 | Tasbīḥ |
| C-7 | Taḥmīd |
| C-8 | Takbīr |
| C-9 | Tahlīl |
| C-10 | Ṣalawāt |
| C-11 | Closing du'ā |

## I — guidance (no audio; TTS by design)
| id | Text |
|---|---|
| I-1 | This is the instructional prayer. You will be guided through all motions… |
| I-2 | Stand for the second rak'ah |
| I-3 | Bow forward, hands on knees |
| I-4 | Rise to standing |
| I-5 | Prostrate, forehead to ground |
| I-6 | Sit upright |
| I-7 | Prostrate again |
| I-8 | Sit for the short Tashahhud |
| I-9 | Stand for the fourth rak'ah |
| I-10 | Stand for the third rak'ah |
| I-11 | Sit for Tashahhud |
| I-12 | Turn your head to the right |
| I-13 | Turn your head to the left |
| I-14 | Please stand |
| I-15 | Please bow into Ruku |
| I-16 | Please return to standing |
| I-17 | Please lower into Sujood |
| I-18 | Please sit up |
| I-19 | Please lower into Sujood again |
| I-20 | Please sit |
| I-21 | Please sit for Tashahhud |
| I-22 | Please turn right |
| I-23 | Please turn left |
| I-24 | Stand upright and put your hands by your side. |
| I-25 | Give your niyet for {prayer} |
| I-26 | Calibration starting. You have fifteen positions to complete. Stand upright — this is Qiyam. |
| I-27 | Ruku. Bow forward and place both hands on your knees. |
| I-28 | Qiyam. Return to standing upright. |
| I-29 | Sujood. Lower into prostration with your forehead touching the ground. |
| I-30 | Julus. Sit upright on your knees. |
| I-31 | Sujood. Lower into prostration again with your forehead touching the ground. |
| I-32 | Qiyam. Stand upright for the second rakat. |
| I-33 | Julus. Sit upright for Tashahhud. |
| I-34 | Tasleem. Turn your head to the right. |
| I-35 | Tasleem. Turn your head to the left. |
| I-36 | Get ready to bow into Ruku. |
| I-37 | Get ready to stand upright into Qiyam. |
| I-38 | Get ready to lower into Sujood. |
| I-39 | Get ready to sit upright into Julus. |
| I-40 | Get ready to lower into Sujood again. |
| I-41 | Get ready to stand upright for the second rakat. |
| I-42 | Get ready to sit for Tashahhud. |
| I-43 | Get ready to turn your head to the right for Tasleem. |
| I-44 | Get ready to turn your head to the left. |
| I-45 | Calibration complete. You may move freely. |
| I-46 | Bow forward and place both hands on your knees. |
| I-47 | Stand upright. |
| I-48 | Lower into prostration with your forehead touching the ground. |
| I-49 | Sit upright on your knees. |
| I-50 | Turn your head to the right. |
| I-51 | Turn your head to the left. |
| I-52 | Hold this position for five seconds. |

## P — recitation (all recorded)
`P-0 … P-23`, each present in `ar`, `en`, `tr` as `sawt-ai-<lang>-P-N.m4a`. No gaps.

> Note on Turkish: the `tr` *audio* is the Turkish **meaning** recording, while the
> `tr` *text* (`prayers.json`) is currently the **transliteration** — a known
> read/hear mismatch to resolve with the language-refactor. German + Turkish-
> transliteration recordings exist in the source but are not imported.
