# SalatMotion — Claude Code Scaffold Prompts

Run these in order, each as a separate Claude Code session against the PrayerMotionSpike repo root. Verify/build between each before moving to the next.

---

## 1. Project Structure + Router

```
Set up the following folder structure in this Xcode project, moving existing
files into their correct new locations (don't rewrite logic, just relocate
and fix imports):

SalatMotion/
  App/                    (App entry point, Router)
  Features/
    Home/
    PrayerSession/
    Settings/
    Onboarding/
  Core/
    MotionDetection/
    PrayerStateMachine/
    Speech/
    Networking/
  DesignSystem/
    Components/
    Tokens/
  Resources/
    Audio/
      Reciters/
      Narration/

Then create a simple enum-based Router using NavigationStack:
- Route enum (cases: home, prayerSession, settings, qiblaCompass, onboarding)
- An @Observable Router class holding a NavigationPath, with push/pop methods
- Wire the App entry point to use this Router as the single source of truth
  for navigation

Don't touch any existing motion detection or state machine logic in this pass
— just relocate files and add the Router.
```

---

## 2. Migrate Motion Detection + State Machine into Core/

```
Move the existing CMHeadphoneMotionManager integration and the 32-state
prayer state machine into Core/MotionDetection/ and Core/PrayerStateMachine/
respectively, per the existing spike code.

Specifically:
- Core/MotionDetection/: the CMHeadphoneMotionManager wrapper, threshold
  constants (Ruku pitch ~-73° to -75°, Sujood roll ~160-164°), and the
  sequence-context disambiguation logic for standing vs sitting
- Core/PrayerStateMachine/: the 32-state machine, trigger types
  (motion-triggered/auto/user-paced), and the 8-second reprompt timer logic

Keep these fully decoupled from any View — they should expose state via
@Observable so a PrayerSession screen can simply observe and render.

Do not fix the known Rakat 1 → Rakat 2 bug in this pass — that's a separate
targeted task next.
```

---

## 3. Audio Asset Structure (Hybrid Reciter/Narration)

```
Set up the audio asset structure under Resources/Audio/:

Resources/Audio/
  Reciters/
    reciter_alafasy/
      manifest.json
      ar/
        takbir.mp3
        ruku.mp3
        sujood_1.mp3
        sujood_2.mp3
        tasleem.mp3
  Narration/
    en/
      manifest.json
      takbir.mp3
      ruku.mp3
      sujood_1.mp3
      sujood_2.mp3
      tasleem.mp3

Use placeholder/empty mp3 files for now — the focus is structure, not content.

Create an AudioManager in Core/Speech/ that:
- Resolves (phraseKey, selectedReciterId) -> Arabic file path via the
  reciter's manifest.json
- Resolves (phraseKey) -> shared English narration file path via
  Narration/en/manifest.json
- Falls back to AVSpeechSynthesizer TTS for English if no Reciter manifest
  override exists, and logs a warning (don't crash) if an Arabic file is
  missing for a given phrase key

The state machine should only ever reference phrase keys — it must have no
awareness of reciters, languages, or file paths.
```

---

## 4. Markdown → JSON Manifest Generator

```
Create a script (Node, run via `node scripts/generate-manifests.js`) that:

1. Parses a single source file at docs/audio-manifest.md containing two
   Markdown tables:
   - "## Reciters" table: rows are phrase keys, columns are reciter names,
     cells are filenames
   - "## English Narration" table: rows are phrase keys, one "File" column

2. Generates:
   - Resources/Audio/Reciters/<reciter_id>/manifest.json for each reciter
     column (reciterId, displayName, language: "ar", files: {phraseKey:
     filename})
   - Resources/Audio/Narration/en/manifest.json (language: "en", files:
     {phraseKey: filename})

3. Validates while generating:
   - Flags any blank/missing cell in the Markdown table
   - Flags any referenced filename that doesn't exist in the corresponding
     ar/ or en/ folder
   - Prints a clear summary of warnings/errors at the end, exits non-zero if
     any file references are missing

Also create the initial docs/audio-manifest.md seeded with the phrase keys
already used in the state machine, one reciter column (Alafasy) and the
English Narration table, all filenames matching the placeholder mp3s from
step 4.
```

---

### Notes
- Steps 1–3 should be run and verified (build succeeds, app launches) before step 4.
- Step 5 only needs to run once asset content actually starts arriving — fine to leave the script idle until then.
- Each prompt deliberately avoids broad diagnostic sweeps per your preference — if Claude Code goes off-script (e.g. tries to "improve" unrelated code), interrupt and redirect.
