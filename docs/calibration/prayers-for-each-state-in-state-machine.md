# Prayers for Each State in the State Machine

Utterances for each position-id in the calibration sequence.
Position-ids correspond to the `position-id` column in `master-prayer-state-machine.md`.

Pattern for every position:
1. **entry** — announces the position name and instructs the user to move into it
2. **prayer** — "Hold this position for five seconds." (5s duration, after motion confirmed)
3. **exit** — names the next position so the user knows what is coming
4. **reprompt** — spoken every 5s while waiting for motion confirmation; short and directive

---

## Position 1 — Qiyam (Standing — Start)

Mode: `timed` — no motion wait. Entry, prayer and exit play in sequence.

| role | utterance | duration |
|---|---|---|
| entry | Calibration starting. You have fifteen positions to complete. Stand upright — this is Qiyam. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to bow into Ruku. | |

---

## Position 2 — Ruku (Bowing — First)

| role | utterance | duration |
|---|---|---|
| entry | Ruku. Bow forward and place both hands on your knees. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to stand upright into Qiyam. | |
| reprompt | Bow forward and place both hands on your knees. | |

---

## Position 3 — Qiyam (Standing — After Ruku, Rakat 1)

| role | utterance | duration |
|---|---|---|
| entry | Qiyam. Return to standing upright. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to lower into Sujood. | |
| reprompt | Stand upright. | |

---

## Position 4 — Sujood (Prostration — First)

| role | utterance | duration |
|---|---|---|
| entry | Sujood. Lower into prostration with your forehead touching the ground. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to sit upright into Julus. | |
| reprompt | Lower into prostration with your forehead touching the ground. | |

---

## Position 5 — Julus (Sitting — Between Prostrations, Rakat 1)

| role | utterance | duration |
|---|---|---|
| entry | Julus. Sit upright on your knees. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to lower into Sujood again. | |
| reprompt | Sit upright on your knees. | |

---

## Position 6 — Sujood (Prostration — Second)

| role | utterance | duration |
|---|---|---|
| entry | Sujood. Lower into prostration again with your forehead touching the ground. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to stand upright for the second rakat. | |
| reprompt | Lower into prostration with your forehead touching the ground. | |

---

## Position 7 — Qiyam (Standing — Rakat 2)

| role | utterance | duration |
|---|---|---|
| entry | Qiyam. Stand upright for the second rakat. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to bow into Ruku. | |
| reprompt | Stand upright. | |

---

## Position 8 — Ruku (Bowing — Second)

| role | utterance | duration |
|---|---|---|
| entry | Ruku. Bow forward and place both hands on your knees. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to stand upright into Qiyam. | |
| reprompt | Bow forward and place both hands on your knees. | |

---

## Position 9 — Qiyam (Standing — After Ruku, Rakat 2)

> Yaw baseline is captured at this position for Tasleem detection.

| role | utterance | duration |
|---|---|---|
| entry | Qiyam. Return to standing upright. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to lower into Sujood. | |
| reprompt | Stand upright. | |

---

## Position 10 — Sujood (Prostration — Third)

| role | utterance | duration |
|---|---|---|
| entry | Sujood. Lower into prostration with your forehead touching the ground. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to sit upright into Julus. | |
| reprompt | Lower into prostration with your forehead touching the ground. | |

---

## Position 11 — Julus (Sitting — Between Prostrations, Rakat 2)

| role | utterance | duration |
|---|---|---|
| entry | Julus. Sit upright on your knees. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to lower into Sujood again. | |
| reprompt | Sit upright on your knees. | |

---

## Position 12 — Sujood (Prostration — Fourth)

| role | utterance | duration |
|---|---|---|
| entry | Sujood. Lower into prostration again with your forehead touching the ground. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to sit for Tashahhud. | |
| reprompt | Lower into prostration with your forehead touching the ground. | |

---

## Position 13 — Julus (Sitting — Tashahhud)

| role | utterance | duration |
|---|---|---|
| entry | Julus. Sit upright for Tashahhud. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to turn your head to the right for Tasleem. | |
| reprompt | Sit upright on your knees. | |

---

## Position 14 — Tasleem (Look Right)

| role | utterance | duration |
|---|---|---|
| entry | Tasleem. Turn your head to the right. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Get ready to turn your head to the left. | |
| reprompt | Turn your head to the right. | |

---

## Position 15 — Tasleem (Look Left)

| role | utterance | duration |
|---|---|---|
| entry | Tasleem. Turn your head to the left. | |
| prayer | Hold this position for five seconds. | 5s |
| exit | Calibration complete. You may move freely. | |
| reprompt | Turn your head to the left. | |
