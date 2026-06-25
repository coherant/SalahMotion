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
| entry | I-1 | F | 5s |
| prayer | I-24 | F | 5s |
| prayer | I-25 | F | 5s |
| prayer | P-0 | F+P | 3s |
| prayer | P-7 | F+P | 2s |
| prayer | P-15 | F+P | 2s |
| prayer | P-0 | F+P | 2s |

---

## RAKAT_FULL — qiyam-full (Rakat 2)
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | I-2 | F |
| reprompt | I-14 | F+P |
| prayer | P-7 | F+P |
| prayer | P-11 | F+P |
| prayer | P-0 | F+P |

---

## RAKAT_FULL — ruku
Mode: `motion` · Motion trigger: pitch (ruku)

| role | utterance | levels |
|---|---|---|
| entry | I-3 | F |
| reprompt | I-15 | F+P |
| prayer | P-1 | F+P |
| prayer | P-1 | F+P |
| prayer | P-1 | F+P |
| exit | P-3 | F+P |

---

## RAKAT_FULL — qiyam-after-ruku
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | I-4 | F |
| reprompt | I-16 | F+P |
| prayer | P-4 | F+P |
| exit | P-0 | F+P |

---

## RAKAT_FULL — sujood-first
Mode: `motion` · Motion trigger: roll (sujood)

| role | utterance | levels |
|---|---|---|
| entry | I-5 | F |
| reprompt | I-17 | F+P |
| prayer | P-2 | F+P |
| prayer | P-2 | F+P |
| prayer | P-2 | F+P |
| exit | P-0 | F+P |

---

## RAKAT_FULL — julus-between
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | I-6 | F |
| reprompt | I-18 | F+P |
| prayer | P-5 | F+P |
| prayer | P-5 | F+P |
| exit | P-0 | F+P |

---

## RAKAT_FULL — sujood-second
Mode: `motion` · Motion trigger: roll (sujood)

| role | utterance | levels |
|---|---|---|
| entry | I-7 | F |
| reprompt | I-19 | F+P |
| prayer | P-2 | F+P |
| prayer | P-2 | F+P |
| prayer | P-2 | F+P |
| exit | P-0 | F+P |

---

## SHORT_TASHAHHUD — julus-short (after Rakat 2)
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | I-8 | F |
| reprompt | I-20 | F+P |
| prayer | P-8 | F+P |

---

## RAKAT_FATIHA_ONLY — qiyam-fatiha (Rakat 3)
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | I-10 | F |
| reprompt | I-14 | F+P |
| prayer | P-7 | F+P |
| prayer | P-0 | F+P |

---

## RAKAT_FATIHA_ONLY — qiyam-fatiha (Rakat 4)
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | I-9 | F |
| reprompt | I-14 | F+P |
| prayer | P-7 | F+P |
| prayer | P-0 | F+P |

---

## FULL_TASHAHHUD — julus-full
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | I-11 | F |
| reprompt | I-21 | F+P |
| prayer | P-8 | F+P |
| prayer | P-9 | F+P |
| prayer | P-10 | F+P |

---

## TASLEEM — tasleem-right
Mode: `motion` · Motion trigger: yaw delta (right)

| role | utterance | levels |
|---|---|---|
| entry | I-12 | F |
| reprompt | I-22 | F+P |
| prayer | P-6 | F+P |

---

## TASLEEM — tasleem-left
Mode: `motion` · Motion trigger: yaw delta (left)

| role | utterance | levels |
|---|---|---|
| entry | I-13 | F |
| reprompt | I-23 | F+P |
| prayer | P-6 | F+P |
| exit | P-23 | F+P |
