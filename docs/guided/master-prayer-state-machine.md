# Master Prayer State Machine

Single source of truth for all guided prayer sequences.
Block definitions: `rakats.md`
Prayer content: `prayer-sets/{prayer}.md`
Prayer text library: `../prayers/prayers.md`

## Notes
- The first Qiyam of any prayer session is `timed` (includes Ezan + niyet)
- All subsequent Qiyams within a session are `motion`
- Yaw baseline is always captured at the last qiyam-after-ruku before TASLEEM

---

## Fajr

### Fajr Sunnah (2 rakats — before Fard)

| # | Block | Rakat |
|---|---|---|
| 1 | RAKAT_FULL | 1 |
| 2 | RAKAT_FULL | 2 · yaw baseline |
| 3 | FULL_TASHAHHUD | 2 |
| 4 | TASLEEM | 2 |

Content: `prayer-sets/fajr.md` · Phase count: 15

---

### Fajr Fard (2 rakats)

| # | Block | Rakat |
|---|---|---|
| 1 | RAKAT_FULL | 1 |
| 2 | RAKAT_FULL | 2 · yaw baseline |
| 3 | FULL_TASHAHHUD | 2 |
| 4 | TASLEEM | 2 |

Content: `prayer-sets/fajr.md` · Phase count: 15

---

## Dhuhr

### Dhuhr Sunnah Before (4 rakats — before Fard)

| # | Block | Rakat |
|---|---|---|
| 1 | RAKAT_FULL | 1 |
| 2 | RAKAT_FULL | 2 |
| 3 | SHORT_TASHAHHUD | 2 |
| 4 | RAKAT_FATIHA_ONLY | 3 |
| 5 | RAKAT_FATIHA_ONLY | 4 · yaw baseline |
| 6 | FULL_TASHAHHUD | 4 |
| 7 | TASLEEM | 4 |

Content: `prayer-sets/dhuhr.md` · Phase count: 28

---

### Dhuhr Fard (4 rakats)

Same block sequence as Dhuhr Sunnah Before.
Content: `prayer-sets/dhuhr.md` · Phase count: 28

---

### Dhuhr Sunnah After (2 rakats — after Fard)

Same block sequence as Fajr Fard.
Content: `prayer-sets/dhuhr.md` · Phase count: 15

---

## Asr

### Asr Sunnah (4 rakats — before Fard · Ghair Mu'akkadah)

Same block sequence as Dhuhr Fard.
Content: `prayer-sets/asr.md` · Phase count: 28

---

### Asr Fard (4 rakats)

Same block sequence as Dhuhr Fard.
Content: `prayer-sets/asr.md` · Phase count: 28

---

## Maghrib

### Maghrib Fard (3 rakats)

| # | Block | Rakat |
|---|---|---|
| 1 | RAKAT_FULL | 1 |
| 2 | RAKAT_FULL | 2 |
| 3 | SHORT_TASHAHHUD | 2 |
| 4 | RAKAT_FATIHA_ONLY | 3 · yaw baseline |
| 5 | FULL_TASHAHHUD | 3 |
| 6 | TASLEEM | 3 |

Content: `prayer-sets/maghrib.md` · Phase count: 22

---

### Maghrib Sunnah After (2 rakats — after Fard)

Same block sequence as Fajr Fard.
Content: `prayer-sets/maghrib.md` · Phase count: 15

---

## Isha

### Isha Fard (4 rakats)

Same block sequence as Dhuhr Fard.
Content: `prayer-sets/isha.md` · Phase count: 28

---

### Isha Sunnah After (2 rakats — after Fard)

Same block sequence as Fajr Fard.
Content: `prayer-sets/isha.md` · Phase count: 15

---

### Witr (3 rakats — after Isha Sunnah)

| # | Block | Rakat |
|---|---|---|
| 1 | RAKAT_FULL | 1 |
| 2 | RAKAT_FULL | 2 |
| 3 | SHORT_TASHAHHUD | 2 |
| 4 | RAKAT_FATIHA_ONLY | 3 · yaw baseline |
| 5 | FULL_TASHAHHUD | 3 |
| 6 | TASLEEM | 3 |

Content: `prayer-sets/witr.md` · Phase count: 22

Note: Witr includes Qunut dua in the final Qiyam — unique to this prayer set.

---

## Phase mode definitions

| Mode | Behaviour |
|---|---|
| `timed` | Plays entry speech, plays prayer rows in sequence, plays exit speech |
| `motion` | Waits indefinitely for confirmed motion (reprompts every reprompt interval), plays entry speech, plays prayer rows in sequence, plays exit speech |

## Motion detection thresholds

See `../calibration/master-prayer-state-machine.md` for calibrated threshold values.
