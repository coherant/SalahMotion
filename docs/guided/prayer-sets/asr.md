# Asr Prayer Set

Used by: Asr Sunnah · Asr Fard
Structure: `../master-prayer-state-machine.md` → Asr
Prayers: `../../prayers/prayers.md`

Note: Asr shares the same 4-rakat block structure as Dhuhr.
Differences from Dhuhr: niyet mention, surah choices in Rakat 2.
Asr Sunnah is Ghair Mu'akkadah (less emphasised).

## Guidance level key
| Symbol | Meaning |
|---|---|
| F | Full guidance only |
| F+P | Full guidance + Prayer only |

---

## RAKAT_FULL — qiyam-full (Opening, Rakat 1)
Mode: `timed`

| role | utterance | levels | duration |
|---|---|---|---|
| entry | Stand upright and raise your hands to your ears | F | — |
| prayer | Listen to the Ezan | F | 5s |
| prayer | Give your niyet for Asr | F | 5s |
| prayer | P-0 | F+P | 3s |
| prayer | P-7 (Al-Fatiha) | F+P | 15s |
| prayer | Al-Asr | F+P | 8s |
| prayer | P-0 | F+P | 2s |

---

## RAKAT_FULL — qiyam-full (Rakat 2)
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | Stand for the second rak'ah | F |
| reprompt | Please stand | F+P |
| prayer | P-7 (Al-Fatiha) | F+P |
| prayer | Al-Ikhlas | F+P |
| prayer | P-0 | F+P |

---

## RAKAT_FULL — ruku
Mode: `motion` · Motion trigger: pitch (ruku)

| role | utterance | levels |
|---|---|---|
| entry | Bow forward, hands on knees | F |
| reprompt | Please bow into Ruku | F+P |
| prayer | P-1 | F+P |
| prayer | P-1 | F+P |
| prayer | P-1 | F+P |
| exit | P-3 | F+P |

---

## RAKAT_FULL — qiyam-after-ruku
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | Rise to standing | F |
| reprompt | Please return to standing | F+P |
| prayer | P-4 | F+P |
| exit | P-0 | F+P |

---

## RAKAT_FULL — sujood-first
Mode: `motion` · Motion trigger: roll (sujood)

| role | utterance | levels |
|---|---|---|
| entry | Prostrate, forehead to ground | F |
| reprompt | Please lower into Sujood | F+P |
| prayer | P-2 | F+P |
| prayer | P-2 | F+P |
| prayer | P-2 | F+P |
| exit | P-0 | F+P |

---

## RAKAT_FULL — julus-between
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | Sit upright | F |
| reprompt | Please sit up | F+P |
| prayer | P-5 | F+P |
| prayer | P-5 | F+P |
| exit | P-0 | F+P |

---

## RAKAT_FULL — sujood-second
Mode: `motion` · Motion trigger: roll (sujood)

| role | utterance | levels |
|---|---|---|
| entry | Prostrate again | F |
| reprompt | Please lower into Sujood again | F+P |
| prayer | P-2 | F+P |
| prayer | P-2 | F+P |
| prayer | P-2 | F+P |
| exit | P-0 | F+P |

---

## SHORT_TASHAHHUD — julus-short (after Rakat 2)
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | Sit for the short Tashahhud | F |
| reprompt | Please sit | F+P |
| prayer | P-8 (Tashahhud only — no Salawat) | F+P |

---

## RAKAT_FATIHA_ONLY — qiyam-fatiha (Rakats 3 & 4)
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | Stand for the next rak'ah | F |
| reprompt | Please stand | F+P |
| prayer | P-7 (Al-Fatiha only) | F+P |
| prayer | P-0 | F+P |

---

## FULL_TASHAHHUD — julus-full
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | Sit for the final Tashahhud | F |
| reprompt | Please sit for Tashahhud | F+P |
| prayer | P-8 (Tashahhud) | F+P |
| prayer | P-9 (Allahumma Salli) | F+P |
| prayer | P-10 (Allahumma Barik) | F+P |

---

## TASLEEM — tasleem-right
Mode: `motion` · Motion trigger: yaw delta (right)

| role | utterance | levels |
|---|---|---|
| entry | Turn your head to the right | F |
| reprompt | Please turn right | F+P |
| prayer | P-6 | F+P |

---

## TASLEEM — tasleem-left
Mode: `motion` · Motion trigger: yaw delta (left)

| role | utterance | levels |
|---|---|---|
| entry | Turn your head to the left | F |
| reprompt | Please turn left | F+P |
| prayer | P-6 | F+P |
| exit | Oh Allah, you are peace and peace comes from you | F+P |
