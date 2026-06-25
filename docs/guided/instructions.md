# Guided Prayer Instructions

Movement guidance spoken to the user during the guided prayer sequence — the
`entry` rows (instruction to move into a position) and `reprompt` rows (nudge
spoken while waiting for motion confirmation).

These are **not prayers**. They are English-only guidance and live here, separate
from the prayer text library (`../prayers/prayers.md`). Reference an instruction
from a `prayer-sets/*.md` row by its `instruction-id` (e.g. `I-1`), exactly the way
`prayer`-role rows reference `P-*`.

`I-1 … I-13` are `entry` instructions; `I-14 … I-23` are `reprompt` instructions;
`I-24 … I-25` are opening cues spoken in the timed first Qiyam. `I-25` is **templated** —
`{prayer}` is replaced at runtime with the prayer's display name (e.g. "Fajr", "Witr").

| instruction-id | instruction |
|---|---|
| I-1 | This is the instructional prayer. You will be guided through all motions. The reciter will give you an instruction to move into a prayer position. When you are in the position, the recitation of the prayer will begin. |
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
