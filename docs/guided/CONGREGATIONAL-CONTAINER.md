# The Congregational Container & Silent Mode — Next Build Arc

**Status: SPEC (not yet built).** This is the vision the whole observance-sequencer
refactor (Stages 0–6, `REFACTOR-PLAN.md`) was building the skeleton for. Captured
2026-06-26 from the design conversation where it crystallised. It **supersedes** the
"Muezzin recites the salah" hybrid sketched earlier and **largely dissolves** the parked
language refactor (`LANGUAGE-REFACTOR.md`) — see *Relationship to other tracks* below.

> Same discipline when we build it: **MD-first**, **golden-snapshot-protected**, small
> reversible stages. See `feedback_md_first`.

---

## 1. The core idea — the fiqh boundary *is* an architectural boundary

An automated Muezzin reciting the obligatory in-salah prayers is jurisprudentially
unsound: the recitation of the farḍ is the **worshipper's own act of worship** and cannot
be performed for them by a recording. The resolution is to relocate the Muezzin **out of
the prayer and into the frame around it**, and to encode that separation in software:

| Role | Voices | Never voices |
|---|---|---|
| **Muezzin / container** | The **call** (Ezan/adhān), the **commencement** (qad qāmat → Iqāma), **punctuation** at each prayer's completion, and **post-salah** devotions (dhikr, ṣalawāt, closing istighfār) | The in-salah recitation |
| **Worshipper** | The **salah itself** — recites every unit, silently, in their own heart | — |

The Muezzin calls, commences, marks boundaries, and leads the dhikr *after*. He never
recites the Fātiḥa, a sūrah, or the tashahhud **for** the worshipper. That single line is
the whole design, and it is enforceable in code (see §4, *Binding policy*).

This is what the id-keyed refactor was *for*: the `PrayerLibrary` (`P-ids`, in-salah) vs
`InstructionLibrary` (`I-ids`, guidance) seam is already the recitation/guidance split.
The container adds a **third namespace** for what the Muezzin legitimately voices.

---

## 2. The Congregational Container (structure)

The container is an **outer shell wrapping the observance we already build** (chained
units from Stages 3–4). No surgery inside the units — a wrapper around them.

```
┌─ CONGREGATIONAL CONTAINER ───────────────────────────────┐
│  [ Ezan / Adhān ]            ← Muezzin (optional; ties to │
│                                 prayer-times)             │
│  Iqāma (qad qāmat)           ← Muezzin — opens container  │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Unit 1  (worshipper prays; guided motion/structure)│  │
│  │     └─ completion → Muezzin: "Allāhumma anta-s-salām"│  │  (P-23 → Muezzin act)
│  │  Unit 2  (worshipper prays …)                        │  │
│  │     └─ completion → Muezzin boundary du'ā            │  │
│  │  … all units complete …                             │  │
│  └────────────────────────────────────────────────────┘  │
│  Closing sequence — Muezzin leads (voiced, auto-paced):   │
│     • Dhikr / tasbīḥāt (Subḥānallāh · Alḥamdulillāh · …)   │
│     • Ṣalawāt on the Prophet ﷺ                            │
│     • Closing du'ā — istighfār, asking forgiveness        │
└──────────────────────────────────────────────────────────┘
```

Maps to the worshipper's words: *Ezan → Iqāma opens the container → worshipper prays each
unit → Muezzin punctuates each completion → after all units, Muezzin leads dhikr +
ṣalawāt + closing du'ā.*

---

## 3. Silent Mode — the timing model (the final stitch)

**You do not time the silent recitation. The worshipper's body times it.** Salah is
intrinsically a **motion-gated state machine**: every posture change is a deliberate
movement the worshipper makes precisely *when their recitation is complete*. The body is
the metronome; the machine already listens to it (`motion` mode, `motionTrigger`).

| Posture | Worshipper recites (silently) | Advances when they… |
|---|---|---|
| Qiyām | Fātiḥa + sūrah | **bow** → Rukūʿ |
| Rukūʿ | "Subḥāna Rabbiyal-ʿAẓīm" | **rise** → iʿtidāl |
| Iʿtidāl | "Rabbanā lakal-ḥamd" | **prostrate** → Sujūd |
| Sujūd | "Subḥāna Rabbiyal-Aʿlā" | **sit up** → Julūs |
| Julūs | "Rabbighfir lī" | **prostrate** → Sujūd |
| Final sitting | Tashahhud + ṣalawāt | **turn the head** → Taslīm |

No gap needs a timer. The recitation duration only ever filled the space *until the next
movement*; in Silent Mode the worshipper fills it themselves, then moves.

**So Silent Mode is almost subtractive:**
- In-salah `prayers[]` rows become **display-only** (Arabic script + meaning on the orb,
  so the worshipper can follow / check themselves). Their `.pace`/`.fixed` durations stop
  driving anything.
- Every posture is **`motion`-gated and patient**: enter → show text → wait, indefinitely,
  for the confirmed movement into the next posture → advance.
- It is essentially *motion mode everywhere, with the voice withdrawn.*

### The three craft details that make it humane
1. **Patience, not nagging.** Today motion states reprompt every `5s`. In Silent Mode that
   rushes someone mid-Fātiḥa. Reprompts go **silent and long — ideally none by default**;
   the worshipper isn't stuck, they're praying. The app must learn to wait in silence.
2. **An escape hatch.** Since only motion advances, a missed sensor read could strand
   someone. After a long, generous hold with no detected movement, offer a gentle
   **tap-to-advance** — always available, never intrusive. Never a hostage to the sensor.
3. **The Muezzin re-entry is where timing returns.** The silent, self-paced span is *only
   the salah itself*. The instant a unit's final Taslīm is confirmed, the worshipper hands
   the clock back and the **Muezzin takes it**: boundary du'ā, then the voiced closing
   container run on the Muezzin's **own recording length** (auto-paced). The timeline
   breathes between two clocks — **the body during the prayer, the Muezzin around it.**
   That handoff *is* the stitch.

### The honest dependency
With no timed fallback advancing anything, the whole experience rests on **motion
detection**. Silent Mode is only as smooth as calibration is accurate — the Rukūʿ/upright
overlap work is no longer a nicety, it's the foundation the silence rests on. The
tap-to-advance hatch is the safety net beneath it. See `[[project_calibration_bug]]`.

---

## 4. What this means in code

**Reused (already built):**
- Units, chaining, unit boundaries, the `unitTransition` ~2s hold — the Muezzin's boundary
  du'ā slots into that existing moment.
- `motion` mode + `motionTrigger` — already the self-pacing mechanism Silent Mode needs.
- `P-23` ("O Allah, You are peace…") — exists; rebind from a passive `exitSpeech` to a
  **Muezzin-voiced boundary act**.
- Id-keyed content; the `PrayerLibrary` / `InstructionLibrary` seam.

**New (additive; clean because everything is id-keyed):**
- A **container phase type** — auto-played, Muezzin-voiced, *listen/follow* states (no
  motion trigger, no rakat). Likely a small sibling to `PrayerState` or a new `PhaseMode`.
  The dhikr may want a **tasbīḥ counter** UI.
- A **third content namespace** (e.g. `C-…`) for what doesn't exist yet: Adhān, Iqāma, the
  post-salah tasbīḥāt, post-salah ṣalawāt, and the closing istighfār/du'ā. A distinct
  namespace makes it **structurally impossible** to confuse container content with salah
  recitation.
- **Binding policy (the fiqh boundary, in code):** a Muezzin voice/recording can bind
  **only** to container (`C-`) ids — never to an in-salah `P-id`. A Muezzin recording for
  `P-7` simply has nowhere to attach. This is configuration, not contradiction.
- A **Silent Mode flag/mode**: in-salah `prayers[]` rows render as text, not speech;
  advancement is purely `motionTrigger`-gated; reprompts patient/suppressed; tap-to-advance
  hatch enabled.
- **In-salah recitation voice = a setting (decision 1c, locked):** default
  **worshipper-recites** (Silent Mode — display only), with an optional **learner
  scaffold** (a neutral teaching voice, explicitly *not* the Muezzin) for those learning.

---

## 5. Relationship to the other tracks

- **Observance arc (`REFACTOR-PLAN.md`, COMPLETE):** built the id-keyed, unit/observance
  skeleton this inhabits. This arc is the *why*.
- **Language refactor (`LANGUAGE-REFACTOR.md`, PARKED):** **largely dissolves here.** With
  the Muezzin out of the salah and in-salah recitation shown as text (Arabic + meaning),
  there is no synthesizer pretending to recite. The axes land honestly: Adhān/Iqāma =
  Arabic (Muezzin); in-salah = displayed (Arabic + meaning, worshipper recites); dhikr /
  closing du'ā = Muezzin voice (Arabic, with the own-language latitude du'ās permit);
  guidance = TTS in the user's language.
- **Prayer-times (`[[project_prayer_times_state]]`, PARKED):** the **Adhān** at the top of
  the container is the same Muezzin who *calls* you to prayer there. One Muezzin identity
  across call-to-prayer and the post-salah frame — the reason "Muezzin" is the right spine,
  not just a voice picker.

---

## 6. Open questions (to resolve before / during build)

- **1c — settled:** in-salah recitation = setting, default worshipper-recites (silent),
  learner scaffold optional.
- **Adhān/Iqāma scope:** Adhān + Iqāma are for the *farḍ* in congregation; sunnah-before is
  prayed individually *before* the Iqāma. Should the container open (Iqāma) wrap **only the
  farḍ onward** (sunnah-before sitting outside/before the container), or embrace the whole
  observance?
- **Boundary du'ā + dhikr placement:** the post-salah "Allāhumma anta-s-salām" and the full
  tasbīḥāt traditionally follow the **farḍ**, not every sunnah unit. Boundary du'ā after
  **every** unit, or specifically after the **farḍ**, with the big dhikr/ṣalawāt/closing
  reserved for the true end?
- **Reprompt policy in Silent Mode:** none at all by default, or a single very-delayed
  gentle cue? Escape-hatch (tap-to-advance) hold-time threshold?
- **Opening:** does the first unit still get the I-1 intro (teaching), or a "begin when
  ready" hand-off straight into self-paced silence?
- **Container content authoring:** Adhān/Iqāma/tasbīḥāt/ṣalawāt/closing du'ā text + the
  `C-` namespace + recordings vs TTS for each.

---

## 7. Likely stages when un-parked (sketch)

1. **Silent Mode (inner):** add the mode — in-salah rows display-only, motion-gated,
   patient reprompts, tap-to-advance hatch. Snapshot-protected. No new content.
2. **The container shell (outer):** wrap the observance — container phase type, `C-`
   namespace, Iqāma open + closing sequence; rebind `P-23` as a Muezzin boundary act.
3. **Muezzin voice binding:** wire `muezzinId` → container audio (the binding policy);
   start TTS-persona, add recordings as a tier.
4. **Adhān + prayer-times join:** the Muezzin's call at the top, tied to prayer-times.

Each stage compiles, builds, and (where it touches the generator) shows a reviewed
golden-snapshot diff.
