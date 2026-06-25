# Witr Prayer Set

Used by: Witr (after Isha Sunnah)
Structure: `../master-prayer-state-machine.md` → Witr
Prayers: `../../prayers/prayers.md`

Note: Witr is 3 rakats and includes the Qunut dua in the final Qiyam before Ruku
of the third rakat — unique to this prayer. Some scholars perform Witr as 1 rakat;
this sequence follows the 3-rakat form.

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
| prayer | I-25 | F | 5s |
| prayer | P-0 | F+P | 3s |
| prayer | P-7 | F+P | 2s |
| prayer | P-16 | F+P | 8s |
| prayer | P-0 | F+P | 2s |

---

## RAKAT_FULL — qiyam-full (Rakat 2)
Mode: `motion` · Motion trigger: pitch (upright)

| role | utterance | levels |
|---|---|---|
| entry | I-2 | F |
| reprompt | I-14 | F+P |
| prayer | P-7 | F+P |
| prayer | P-17 | F+P |
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

## RAKAT_FATIHA_ONLY — qiyam-fatiha with Qunut (Rakat 3)
Mode: `motion` · Motion trigger: pitch (upright)

Note: Qunut dua is recited in this Qiyam after Al-Fatiha, before Ruku.

| role | utterance | levels |
|---|---|---|
| entry | I-10 | F |
| reprompt | I-14 | F+P |
| prayer | P-7 | F+P |
| prayer | P-18 | F+P |
| prayer | P-19 | F+P |
| prayer | P-20 | F+P |
| prayer | P-21 | F+P |
| prayer | P-22 | F+P |
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
