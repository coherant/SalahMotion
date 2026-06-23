# Calibration Master Prayer State Machine

Single source of truth for the calibration sequence and validated motion thresholds.
Guided prayer sequence: `../guided/master-prayer-state-machine.md`

## Source files

| File | Purpose |
|---|---|
| `SalahMotion/Core/PrayerStateMachine/PrayerSequence.swift` | `CalibrationSequenceGenerator` — edit here to change the sequence |
| `SalahMotion/Core/PrayerStateMachine/PrayerStateMachine.swift` | Runtime engine — all four modes, session recording, TTS, idle timer |
| `SalahMotion/Core/PrayerStateMachine/CalibrationAnalyzer.swift` | Derives `UserCalibrationProfile` from recorded session samples |
| `SalahMotion/Core/PrayerStateMachine/UserCalibrationProfile.swift` | Persists calibrated thresholds to UserDefaults |
| `SalahMotion/Features/Settings/CalibrationView.swift` | Personal calibration UI |
| `SalahMotion/Features/Settings/GlobalCalibrationView.swift` | Researcher recording tool (multi-participant data collection) |

## Phase modes

| Mode | Behaviour |
|---|---|
| `auto` | Plays entry speech, plays exit speech, advances immediately — no timer, no motion gate |
| `timed` | Plays entry speech, plays prayer rows in sequence, plays exit speech |
| `motion` | Waits indefinitely for confirmed motion (reprompts every reprompt interval), plays entry speech, plays prayer rows in sequence, plays exit speech |
| `timed-motion` | Plays entry speech, plays prayer rows in sequence (each followed by its duration pause), plays exit speech — motion detection runs throughout; reprompts fire every reprompt interval if position not yet confirmed |

## Timing ownership

Defines which file or constant controls each timing parameter.

| Timer | Controlled by | Location |
|---|---|---|
| Phase duration (how long each position lasts) | Prayer row `duration` values | `prayers-for-each-state-in-state-machine.md` |
| Motion confirmation hold window | Fixed code constant | `PrayerStateMachine.swift` — 1.5s |
| Reprompt interval | Master sequence table | `master-prayer-state-machine.md` — `Reprompt Interval` column |
| Reprompt utterance | Prayer role row | `prayers-for-each-state-in-state-machine.md` — `reprompt` role |

## Master phase sequence

| position-id | Label | Arabic | English Meaning | Mode | Motion Trigger | Reprompt Interval |
|---|---|---|---|---|---|---|
| 1 | Qiyam | قِيَام | Standing | `timed` | — | — |
| 2 | Ruku | رُكُوع | Bowing | `motion` | pitch (ruku) | 5s |
| 3 | Qiyam | قِيَام | Standing | `motion` | pitch (upright) | 5s |
| 4 | Sujood | سُجُود | Prostration | `motion` | roll (sujood) | 5s |
| 5 | Julus | جُلُوس | Sitting | `motion` | pitch (upright) | 5s |
| 6 | Sujood | سُجُود | Prostration | `motion` | roll (sujood) | 5s |
| 7 | Qiyam | قِيَام | Standing | `motion` | pitch (upright) | 5s |
| 8 | Ruku | رُكُوع | Bowing | `motion` | pitch (ruku) | 5s |
| 9 | Qiyam | قِيَام | Standing | `motion` | pitch (upright) | 5s |
| 10 | Sujood | سُجُود | Prostration | `motion` | roll (sujood) | 5s |
| 11 | Julus | جُلُوس | Sitting | `motion` | pitch (upright) | 5s |
| 12 | Sujood | سُجُود | Prostration | `motion` | roll (sujood) | 5s |
| 13 | Julus | جُلُوس | Sitting | `motion` | pitch (upright) | 5s |
| 14 | Tasleem | تَسْلِيم | Salutation | `motion` | yaw delta (right) | 5s |
| 15 | Tasleem | تَسْلِيم | Salutation | `motion` | yaw delta (left) | 5s |

## Parameter definitions

| Parameter | Applies to | Meaning |
|---|---|---|
| `Motion Trigger` | `motion`, `timed-motion` | Sensor condition that must be satisfied to confirm the position |
| `Reprompt Interval` | `motion`, `timed-motion` | How often the reprompt fires while waiting for motion confirmation |

## Motion detection thresholds

Threshold values are updated by calibration runs. The `Initial` column records the
hand-tuned starting point; `Calibrated` records the value derived from data.
The Swift implementation in `PrayerStateMachine.swift` always uses the calibrated value.

| Position | Signal | Initial | Calibrated | Source |
|---|---|---|---|---|
| Ruku | Pitch | [-80°, -65°] | [-82°, -48°] | 3 participants, Jun 2026 |
| Sujood | Roll | angDist(roll, 162.5°) ≤ 12.5° | angDist(roll, 180°) ≤ 30° | 3 participants, Jun 2026 |
| Upright (standing or sitting) | Pitch | [-30°, +25°] | [-40°, +6°] | 3 participants, Jun 2026 |
| Tasleem right | Yaw delta | yaw − baseline ≥ +30° | baseline − yaw ≥ 30° | 3 participants, Jun 2026 |
| Tasleem left | Yaw delta | baseline − yaw ≥ 30° | yaw − baseline ≥ 30° | 3 participants, Jun 2026 |

Notes:
- Upright: sequence position disambiguates standing vs sitting — roll is NOT a hard gate
- Sujood: angular distance handles the ±180° Euler-angle wraparound
- Tasleem: yaw is session-relative; baseline captured at phase 9. Right/left directions confirmed by calibration data (right turn = negative yaw delta)

## Sensor smoothing
7-sample moving average applied to pitch, roll, yaw before threshold evaluation.
Reduces sensor jitter without masking real transitions.

## Yaw baseline
Captured at phase 9 (Standing — After Ruku, Rakat 2) — the most recent confirmed
standing position before Tasleem. Yaw is session-relative so must be captured within
the same session.
