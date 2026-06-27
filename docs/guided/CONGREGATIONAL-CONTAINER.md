# The Congregational Container & Silent Mode — Next Build Arc

**Status: SPEC (not yet built).** This is the vision the whole observance-sequencer
refactor (Stages 0–6, `REFACTOR-PLAN.md`) was building the skeleton for. Captured
2026-06-26 from the design conversation where it crystallised. It **supersedes** the
"Muezzin recites the salah" hybrid sketched earlier and **largely dissolves** the parked
language refactor (`LANGUAGE-REFACTOR.md`) — see *Relationship to other tracks* below.

> Same discipline when we build it: **MD-first**, **golden-snapshot-protected**, small
> reversible stages. See `feedback_md_first`.

> ⚠️ **Scope — CORE ONLY. This doc describes the state machine, not the view.** The state
> machine is the canonical, idempotent core; the view merely renders it. Document here only
> *behavior and the model*: phase modes, generator/injection, content namespaces, the fiqh
> binding policy, advancement/timing, published state. **Do NOT add view-layer rendering**
> — colours, hex values, fonts, spacing, SwiftUI modifiers (`.opacity`, `.saturation`, …),
> component names used *as styling*, layout, animation, "looks like / chrome." Those live in
> the feature's Claude Design SPEC (`docs/features/guided-prayer/SPEC.md`), never here.
>
> **Litmus test:** if a line would change when only the *appearance* changes, it does not
> belong in this doc. ("Fades in" fails — strip it; "60s with no motion → allow manual
> advance" passes — keep it.)
>
> **Allowed for traceability:** naming the **published state** (`tasbihRemaining`,
> `isSpeaking`, `visitedStates`, …) and **the view that consumes it** (e.g. "`runSilentPhase`
> is driven from `GuidedPrayerView`"). The rule is about **appearance, not references** —
> describe the data/behavior and where it is read, never how it looks. See
> `feedback_core_vs_view`.

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

> **Worked references — `container-sets/`** (each maps this onto one prayer phase-by-phase,
> the way `prayer-sets/` anchors the inner units):
> - `fajr.md` — Sunnah→Farḍ; the carrier of *aṣ-ṣalātu khayrun mina-n-nawm*; degenerate tail.
> - `dhuhr.md` — Sunnah→Farḍ→Sunnah-after; sets the **two-anchor** tail rule.
> - `asr.md` — Sunnah(optional)→Farḍ; Fajr-degenerate at 4+4.
> - `maghrib.md` — Farḍ→Sunnah-after; **no sunnah-before** (Ezan→Iqāma directly); 3-rakʿah farḍ.
> - `isha.md` — Sunnah→Farḍ→Sunnah-after→**Witr**; seal **after** the Witr; flags the Isha
>   composition bug (missing sunnah-before).

---

## A. Container Call Library (`C-` ids)

The Muezzin's content namespace — the parallel to `docs/prayers/prayers.md` (`P-ids`). None
of these exist yet. When built, this graduates to its own `calls.md` (mirroring
`prayers.md`); kept inline here while in SPEC. **Binding policy:** a Muezzin recording binds
**only** to a `C-` id, never a `P-id` (see §4).

| id | name | text (transliteration) | meaning | shape |
|---|---|---|---|---|
| `C-1` | Adhān | Allāhu akbar ×4 · Ashhadu an lā ilāha illā-llāh ×2 · Ashhadu anna Muḥammadan rasūlu-llāh ×2 · Ḥayya ʿalā-ṣ-ṣalāh ×2 · Ḥayya ʿalā-l-falāḥ ×2 · Allāhu akbar ×2 · Lā ilāha illā-llāh ×1 | The call to prayer | call |
| `C-1F` | Adhān (Fajr) | …as `C-1`, **with** *Aṣ-ṣalātu khayrun mina-n-nawm* ×2 after *Ḥayya ʿalā-l-falāḥ* | "Prayer is better than sleep" — Fajr only | call |
| `C-2` | Iqāma | …as adhān phrases (Ḥanafī doubles them), **plus** *Qad qāmati-ṣ-ṣalāh* ×2 before the closing takbīr | The prayer has begun | call |
| `C-3` | Boundary du'ā | *Allāhumma anta-s-salām wa minka-s-salām, tabārakta yā dhā-l-jalāli wa-l-ikrām* — **= `P-23`** | O God, You are Peace… | boundary |
| `C-4` | Istighfār | *Astaghfirullāh* ×3 | I seek God's forgiveness | dhikr |
| `C-5` | Āyat al-Kursī | Qur'an 2:255 (*Allāhu lā ilāha illā huwa-l-Ḥayyu-l-Qayyūm…*) | The Throne Verse — *the best gem* | dhikr |
| `C-6` | Tasbīḥ | *Subḥānallāh* ×33 | Glory be to God | dhikr |
| `C-7` | Taḥmīd | *Alḥamdulillāh* ×33 | All praise to God | dhikr |
| `C-8` | Takbīr | *Allāhu akbar* ×33 | God is the Greatest | dhikr |
| `C-9` | Tahlīl | *Lā ilāha illā-llāhu waḥdahu lā sharīka lah, lahu-l-mulku wa lahu-l-ḥamd, wa huwa ʿalā kulli shay'in qadīr* | …completes 100 | dhikr |
| `C-10` | Ṣalawāt | *Allāhumma ṣalli ʿalā Muḥammad…* | Blessings upon the Prophet ﷺ | dhikr |
| `C-11` | Closing du'ā | Free supplication — istighfār, asking acceptance (hands raised) | — | closing |

`C-3` is the same text as the in-salah-adjacent `P-23`; it is a *post-salah* act, so it
lives honestly in the container. One source, re-voiced by the Muezzin — not duplicated.

## B. The dhikr count is **not** a madhab axis

The post-salah tasbīḥ counts come from **multiple authentic hadith**, not from the four
schools diverging. All four treat post-salah tasbīḥ as *mustaḥabb* from the same narrations;
picking a formula is choosing *which sunnah narration*, not which madhab.

**Locked default: 33 Subḥānallāh · 33 Alḥamdulillāh · 33 Allāhu akbar · + 1 tahlīl = 100**
(Muslim) — the most widely practiced, including the Turkish/Ḥanafī tradition this Muezzin
belongs to. (Alternative narrations: 33/33/34; 25×4; 10×3 — all valid; could be an optional
*formula* setting later, but it is **not** wired to the madhab toggle.)

What genuinely *is* madhab-driven nearby — and must not be conflated: **Qunūt** (Ḥanafī =
Witr only → Fajr carries none), and **unit composition** (already in `SalatType.units`).
Āyat al-Kursī after the farḍ is broadly recommended across schools — **included**.

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

### The advancement model (resolved — what "motion everywhere" means in code)

The generated sequence uses only **two** modes in practice: `motion` (303 states) and
`timed` (6 states — the opening `r1QiyamFull` of each observance). `.auto`/`.timedMotion`
are defined but unused. Silent Mode **needs no generator change — the golden snapshot stays
byte-identical**; it is implemented as a single `runSilentPhase` runner that overrides the
per-mode runners while `guidanceLevel == .silent`.

**The principle: dwell, then depart.** A posture's recitation happens *while you are in it*;
you leave it by making the *next* movement. So in Silent Mode each state shows its text
(display-only) and **advances on the *departure* — the next state's trigger**
(`states[i+1].motionTrigger`), waited for patiently and indefinitely. This keeps the display
on the posture the worshipper is actually in (e.g. Rukūʿ stays up, reciting, until they
*rise*), rather than the today-model's "wait for this posture's *arrival*," which would flip
the display a step early once the voice/timer is removed. The state's own arrival trigger was
already consumed by the previous state's departure-wait, so it isn't re-waited — no
double-hold.

**The one exception — the movement the sensor can't see.** Detection is by AirPods *head
attitude*; **standing up from sitting is invisible** (a seated tashahhud reads as "upright,"
identical to standing). That bites at the **middle tashahhud → next rakʿah** and at **unit
boundaries**. There, Silent Mode bridges with a **short timed dwell** sized to the seated
recitation (`Σ prayer durations`, floor 2s), then advances automatically — *the body is the
clock everywhere the body is visible; a recitation-length hold only where it isn't.* In code:
`runSilentPhase` takes the timed-dwell branch when the departure trigger is `.upright` **and**
the current posture is seated (`isSeatedUpright`); the final taslīm also dwells briefly, then
completes.

**No reprompts, no fallback.** Visible-departure waits run through `confirmMotion`, which in
silent mode emits **no reprompt audio** and **disables the `maxReprompts` fallback advance** —
it waits forever. A tap (the escape hatch, below) is the only non-motion way forward.

**The opening teaching intro (`I-1`) and timed niyet rows** are `playsEntryGuidance` /
`playsPrayers` content — already gated off in `.silent`. So the opening is a quiet "begin when
ready," not the full instructional walk-through. *(Answers the §6 "Opening" question.)*

### The three craft details that make it humane
1. **Patience, not nagging — LOCKED: total silence.** Today motion states reprompt every
   `5s`, which would rush someone mid-Fātiḥa. In Silent Mode there are **no reprompts at
   all** — no audio, no visual nudge. The app waits **indefinitely**; the `maxReprompts`
   fallback-advance is disabled. The worshipper isn't stuck, they're praying.
2. **An escape hatch — LOCKED: tap appears after a long hold.** Since only motion advances,
   a missed sensor read could strand someone. The screen stays pure; after **~60s in one
   posture with no confirmed movement**, a gentle **"Tap to continue"** fades in. Tapping
   advances to the next posture. Hidden until needed, never intrusive — and it doubles as
   manual pacing for anyone who wants it.
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
- A **container phase type — DECIDED (Stage 2b): extend `PhaseMode`, not a new struct.** A
  container row is a `PrayerState` with `mode ∈ {.listen, .count}` and a new optional
  `callID: CallID?` (nil for in-salah rows). This reuses the entire generator / snapshot /
  tracker / CSV pipeline rather than forking a parallel row type.
  - `.listen` — a single call/recitation, auto-paced, advances on completion (adhān, iqāma,
    boundary du'ā, āyat al-Kursī, ṣalawāt, closing). `runListenPhase`.
  - `.count` — a counted dhikr; the worshipper repeats to `CallLibrary.count(callID)` via a
    **tasbīḥ counter** (`tasbihRemaining` published, `tapTasbih()` decrements). `runCountPhase`.
  - Both carry a **tap-to-advance** hatch and are **exempt from Silent Mode** (the Muezzin's
    frame is meant to be heard — the run loop routes container rows past `runSilentPhase`).
  - **Stage 2b builds the runners as structural shells — nothing is voiced yet** (voice
    binding is Stage 3); `.listen` dwells on an interim paced hold, `.count` drives the
    counter. No container rows are generated until Stage 2c, so the golden snapshot stays
    byte-identical through 2b.
  - **Stage 2d — tasbīḥ counter scaffolding: tap wired later (decided).** A `.count` row
    publishes `tasbihRemaining`; the **tap scaffolding is in place** (`tapTasbih()` already
    decrements) but is **not yet bound to a control**, so a `.count` row advances via the
    existing tap-to-advance hatch for now. (Counter presentation is view-layer — out of scope
    for this doc.)
  - **Stage 2e — container behind a toggle + voiced via current TTS (decided 2026-06-26,
    default OFF).** A `UserPreferences.muezzinEnabled` flag (persisted; **default off** until
    the frame can be heard) gates the whole frame.
    `generate(…, container: Bool = UserPreferences.shared.muezzinEnabled)` wraps the entire 2c
    injection (Iqāma + boundary du'ā + seal) in `if container`; **off → the byte-for-byte
    pre-container sequence** (no `C-` rows emitted, so nothing downstream ever sees a
    container). The golden snapshot pins `container: true` in the test, so it stays
    byte-identical regardless of the default.
  - **Voice (decided): enabling the Muezzin makes it SPEAK now, via the current TTS tier** — an
    early down-payment on Stage 3, not the full persona-recording binding. `runListenPhase` /
    `runCountPhase` call `speakContainerCall(state)` → `audioManager.speak(CallLibrary.
    transliteration(callID))` in the user's language voice (consistent with the in-salah
    pipeline, which speaks the romanized utterance, **not** Arabic script — also sidesteps the
    unverified C-1/1F/2/5/11 Arabic). `.listen` advances when the speech finishes; `.count`
    voices once then runs the counter. A tap during speech is consumed so it never leaks into
    the next row. **Still pending for Stage 3:** persona-specific Muezzin voices/recordings (the
    circle selection is inert until then).
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
- **Adhān/Iqāma scope — SETTLED (via `container-sets/fajr.md`):** the **Iqāma opens the
  container between sunnah and farḍ** (sunnah-before is prayed before it, as in
  congregation); the **Ezan is a pre-roll** above the container, prayer-time-tied. Generalise
  to the other four when mapped.
- **Boundary du'ā + dhikr placement — SETTLED (general rule, via `container-sets/dhuhr.md`):**
  two acts, two anchors —
  1. **Boundary du'ā `C-3`** (*Allāhumma anta-s-salām*) fires **immediately after the FARḌ**
     unit (the du'ā of exiting the obligatory prayer; punctuates farḍ → sunnah-after).
  2. **Full dhikr `C-4…C-10` + closing `C-11`** **seal the whole observance** — after the
     **last** unit.
  Matches Turkish/Ḥanafī practice (*entesselâm* after the farz; **tesbîhât** after the
  son-sünnet). **Fajr is the degenerate case** (farḍ *is* last → both anchors coincide).
  Never after a sunnah-**before** (the Iqāma marks that). **Build implication:** `C-3` is a
  **new emission point** after the *farḍ* — today `P-23` fires only on the *last* unit; the
  container splits that single closing into *(boundary-after-farḍ)* + *(seal-at-end)*.
- **Dhikr formula — SETTLED:** 33/33/33 + tahlīl; Āyat al-Kursī included (see §B).
- **Witr placement — SETTLED (via `container-sets/isha.md`):** the seal falls **after the
  Witr**. Witr is the last unit, so the general "seal after the last unit" rule holds with
  **no special case**. The Muezzin is **silent through the Witr** — its Qunūt is in-salah
  recitation, which he never voices — then seals once it's complete.
- **Isha composition — FIXED (`ea5cb8c`, build Stage 0):** full Ḥanafī Isha is **4→4→2→3**
  (13 rakʿah). `isha_sb` added (`SalatType.units` `.isha`; `observances.md` §1 + §5;
  `prayer-sets/isha.md`; surahs Al-ʿAsr `P-15` / Al-Kāfirūn `P-17`); snapshot regenerated
  Isha 65 → 93, green.
- **Taslīm not detected — FIXED + CONFIRMED ON DEVICE 2026-06-26 (un-deferred; observance
  arc was already complete). Verified live in both Guided and Silent — head-turn salām
  registers on both turns. Snapshot green.** The
  fix landed exactly as sketched: capture `qiyamYawBaseline = yaw` at the final sitting, the
  instant before the *first* turn — non-silent in `runMotionPhase` when `motionTrigger ==
  .headTurnRight`, *before* the entry cue; silent in `runSilentPhase` when `nextTrigger ==
  .headTurnRight`, before `confirmMotion`. `tasleemLeft` keeps that forward baseline (not
  re-sampled). **Clean relocation (2026-06-26):** the old `capturesYawBaseline` flag was
  removed entirely — the `PrayerState` field, the run-loop capture block (old `:196`), the
  generator threading, and the snapshot `yaw=` column — so the final-sitting capture is now the
  *sole* baseline source (spec ↔ code agree; calibration's use of the flag was parked and
  stripped separately). Snapshot regenerated green — dropping the `yaw=` column means it is
  **not** byte-identical, so the golden file was re-promoted. A `[PrayerSM] 📐 Taslīm baseline`
  log marks the capture for device verification. Diagnosis retained below for the record.
  The head-turn taslīm is the *only* yaw-based posture, and it failed
  to register across **all three** guidance levels (Full, Prayer-only, Silent) — which
  localises it to the one thing they share: the **yaw baseline**, not the per-mode runners.
  Root cause: the baseline (`qiyamYawBaseline`) is captured once at **`r2QiyamAfterRuku`**
  (`capturesYawBaseline`, run loop `PrayerStateMachine.swift:196`, sampled *after* the phase
  returns — already heading into the first sujood) and then *used* two prostrations later at
  `tasleemRight`/`tasleemLeft`. Two failure modes, both mode-independent: (1) sampled
  too-early/mid-motion so "forward" is already tilted; (2) AirPods yaw heading **drifts**
  through the two intervening sujoods, so the head-turn delta never crosses threshold.
  Everything pitch/roll-based (rukūʿ, sujood, sit) is unaffected — exactly the observed
  symptom. **Proposed fix (≈6 lines, snapshot byte-identical):** capture `qiyamYawBaseline =
  yaw` at the final sitting, the instant before the *first* turn, in each model —
  non-silent: first line of `runMotionPhase` when `motionTrigger == .headTurnRight`
  (`tasleemRight`), before any entry cue could prompt an early turn; silent: in
  `runSilentPhase` when `nextTrigger == .headTurnRight` (`julusFull`), before `confirmMotion`.
  `tasleemLeft` keeps that same forward baseline (head already turned — must *not* re-sample);
  the old early capture becomes harmlessly overwritten in every mode (no sequence change).
  **⚠️ Overwrite-ordering hazard — now RESOLVED by the clean relocation.** Historically
  `qiyamYawBaseline` was a single shared var written in *two* places — the run-loop
  `capturesYawBaseline` block (fired *after* each phase) and the pre-turn capture — so a
  `capturesYawBaseline` state running *after* the good forward capture could clobber the
  baseline mid-taslīm (e.g. moving the flag onto `julusFull` breaks Silent, which departs on
  `headTurnRight` and would resample with the head already turned right, killing the second
  turn `headTurnLeft`). Removing the flag eliminates the second write site entirely: the
  final-sitting capture is now structurally the *only* write before each taslīm pair, so the
  ordering hazard can no longer occur. The `[PrayerSM] 📐` log remains for on-device
  confirmation. Same yaw/detection neighbourhood as the calibration overlap bug (parked).
- **Reprompt policy in Silent Mode — SETTLED:** **total silence** (no reprompts, audio or
  visual; `maxReprompts` fallback disabled; wait indefinitely). Escape hatch = **"Tap to
  continue" after ~60s** in one posture with no confirmed motion (see §3 craft detail 2).
- **Opening — SETTLED:** Silent Mode gets a quiet "begin when ready," not the `I-1`
  teaching intro — `I-1`/timed niyet rows are `playsEntryGuidance`/`playsPrayers` content,
  already gated off in `.silent` (see §3, advancement model).
- **Container content authoring:** Adhān/Iqāma/tasbīḥāt/ṣalawāt/closing du'ā text + the
  `C-` namespace + recordings vs TTS for each.

---

## 7. Likely stages when un-parked (sketch)

1. **Silent Mode (inner) — BUILT (pending on-device verification).** `runSilentPhase` +
   `confirmMotion`/`timedSilentDwell` in `PrayerStateMachine`; escape-hatch tap in
   `GuidedPrayerView`. In-salah rows already display-only; motion-gated dwell-then-depart;
   total silence (no reprompts, no fallback); short timed dwell only at the invisible
   sit→stand; "Tap to continue" after 60s. Snapshot byte-identical; build + snapshot green.
   *Still to confirm on a device with AirPods: dwell feel, the 60s hatch, the tashahhud
   bridge.*
2. **The container shell (outer):** wrap the observance — container phase type, `C-`
   namespace, Iqāma open + closing sequence; rebind `P-23` as a Muezzin boundary act.
3. **Muezzin voice binding:** wire `muezzinId` → container audio (the binding policy);
   start TTS-persona, add recordings as a tier.
4. **Adhān + prayer-times join:** the Muezzin's call at the top, tied to prayer-times.

Each stage compiles, builds, and (where it touches the generator) shows a reviewed
golden-snapshot diff.
