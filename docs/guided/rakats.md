# Rakat Blocks

Reusable building blocks for composing prayer sequences.
Each block defines position order, motion triggers and modes only.
Actual prayer content (utterances) is defined per-prayer in `prayer-sets/`.

---

## How blocks compose into prayers

| Prayer  | Rakats | Sequence |
|---|---|---|
| Fajr    | 2 | RAKAT_FULL → RAKAT_FULL → FULL_TASHAHHUD → TASLEEM |
| Maghrib | 3 | RAKAT_FULL → RAKAT_FULL → SHORT_TASHAHHUD → RAKAT_FATIHA_ONLY → FULL_TASHAHHUD → TASLEEM |
| Dhuhr   | 4 | RAKAT_FULL → RAKAT_FULL → SHORT_TASHAHHUD → RAKAT_FATIHA_ONLY → RAKAT_FATIHA_ONLY → FULL_TASHAHHUD → TASLEEM |
| Asr     | 4 | RAKAT_FULL → RAKAT_FULL → SHORT_TASHAHHUD → RAKAT_FATIHA_ONLY → RAKAT_FATIHA_ONLY → FULL_TASHAHHUD → TASLEEM |
| Isha    | 4 | RAKAT_FULL → RAKAT_FULL → SHORT_TASHAHHUD → RAKAT_FATIHA_ONLY → RAKAT_FATIHA_ONLY → FULL_TASHAHHUD → TASLEEM |

Note: Dhuhr, Asr and Isha share the same block sequence.
Their differences live entirely in their `prayer-sets/` files.

---

## RAKAT_FULL
Used for: Rakats 1 & 2 in all prayers.
Qiyam includes Al-Fatiha + an additional surah.

| position | Label | Arabic | English Meaning | Mode | Motion Trigger | Reprompt |
|---|---|---|---|---|---|---|
| qiyam-full | Qiyam | قِيَام | Standing | `timed` | — | — |
| ruku | Ruku | رُكُوع | Bowing | `motion` | pitch (ruku) | 5s |
| qiyam-after-ruku | Qiyam | قِيَام | Standing | `motion` | pitch (upright) | 5s |
| sujood-first | Sujood | سُجُود | Prostration | `motion` | roll (sujood) | 5s |
| julus-between | Julus | جُلُوس | Sitting | `motion` | pitch (upright) | 5s |
| sujood-second | Sujood | سُجُود | Prostration | `motion` | roll (sujood) | 5s |

---

## RAKAT_FATIHA_ONLY
Used for: Rakats 3 & 4 in 4-rakat prayers. Rakat 3 in Maghrib.
Qiyam includes Al-Fatiha only — no additional surah.

| position | Label | Arabic | English Meaning | Mode | Motion Trigger | Reprompt |
|---|---|---|---|---|---|---|
| qiyam-fatiha | Qiyam | قِيَام | Standing | `motion` | pitch (upright) | 5s |
| ruku | Ruku | رُكُوع | Bowing | `motion` | pitch (ruku) | 5s |
| qiyam-after-ruku | Qiyam | قِيَام | Standing | `motion` | pitch (upright) | 5s |
| sujood-first | Sujood | سُجُود | Prostration | `motion` | roll (sujood) | 5s |
| julus-between | Julus | جُلُوس | Sitting | `motion` | pitch (upright) | 5s |
| sujood-second | Sujood | سُجُود | Prostration | `motion` | roll (sujood) | 5s |

---

## SHORT_TASHAHHUD
Used for: Between Rakat 2 and Rakat 3 in all 3+ rakat prayers.
User sits, recites Tashahhud only (no Salawat), then stands to continue.

| position | Label | Arabic | English Meaning | Mode | Motion Trigger | Reprompt |
|---|---|---|---|---|---|---|
| julus-short | Julus | جُلُوس | Sitting | `motion` | pitch (upright) | 5s |

Note: exit from this block is standing — leads directly into the next RAKAT block's qiyam.

---

## FULL_TASHAHHUD
Used for: Final rakat of all prayers.
User sits, recites full Tashahhud + Salawat (Ibrahimiyya) + personal dua.

| position | Label | Arabic | English Meaning | Mode | Motion Trigger | Reprompt |
|---|---|---|---|---|---|---|
| julus-full | Julus | جُلُوس | Sitting | `motion` | pitch (upright) | 5s |

Note: content (number of duas, specific prayers) differs per prayer — see `prayer-sets/`.

---

## TASLEEM
Used for: End of all prayers. Yaw baseline must be captured at the
final qiyam-after-ruku before this block begins.

| position | Label | Arabic | English Meaning | Mode | Motion Trigger | Reprompt |
|---|---|---|---|---|---|---|
| tasleem-right | Tasleem | تَسْلِيم | Salutation | `motion` | yaw delta (right) | 5s |
| tasleem-left  | Tasleem | تَسْلِيم | Salutation | `motion` | yaw delta (left)  | 5s |

---

## Notes

- **Yaw baseline**: always captured at the last `qiyam-after-ruku` before TASLEEM
- **rakatNumber**: assigned by the sequence composer in `master-prayer-state-machine.md`, not defined here
- **Position IDs in Swift**: generated as `rakat{N}_{position}` e.g. `rakat1_qiyamFull`, `rakat3_ruku`
