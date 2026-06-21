# Global Configurations

Settings that apply across all prayer profiles (calibration, guided, etc.).

---

## How Claude should build from this file

When reading this file to generate or update Swift code:

1. **Location** — all flags map to `PrayerStateMachine.swift` unless noted otherwise.
2. **Default value** — use the value marked `(default)` when generating the `init` signature.
3. **Build scope** — changes here apply to both `PrayerSequenceGenerator` and `GuidedSequenceGenerator` unless a flag is marked profile-specific.

---

## Audio Route

Controls which output device speech is sent to during a session.

| Value | Behaviour | Notes |
|---|---|---|
| `speakerOnly` | Forces built-in iPhone speaker, even if AirPods are connected | Useful for testing without AirPods in ear |
| `headphones` | Routes to AirPods if connected, falls back to speaker if not (default) | Normal guided/calibration use |
| `auto` | iOS decides based on connected devices | Same as `headphones` in practice |

**Default:** `headphones`

**Wire-up:** `AudioRoute` enum + init parameter on `PrayerStateMachine`; applied inside `configureAudioSession()` by inserting `.defaultToSpeaker` into `AVAudioSession.CategoryOptions` when value is `speakerOnly`.

> **Note:** iOS does not support simultaneous speaker + AirPods output from a single audio session. "Speaker and headphones at once" would require two separate audio players and is not currently planned.

---

## Tab Wiring

Controls which sequence generator and participant name behaviour each tab uses. When building, apply the values in this table to the `PrayerStateMachine(sequence:participantName:)` call in the relevant SwiftUI view.

| Tab | View | Sequence Generator | Participant Name | CSV Prefix |
|---|---|---|---|---|
| Guided | `ReactivePrayerView` | `GuidedSequenceGenerator` | Not required (empty string) | `prayer_session_` |
| Calibration | `GuidedRecordingView` | `GuidedSequenceGenerator` | Required (user-entered, blocks start if empty) | `prayer_calibration_` |

**How Claude should build from this table:**
1. For each tab, find the view named in the `View` column.
2. Every `PrayerStateMachine(...)` initialisation in that view must pass `sequence: <Sequence Generator>.generate()`.
3. If `Participant Name` is `Required`, ensure the start button is disabled when the name field is empty and the name is passed as `participantName:`.
4. The `CSV Prefix` column is informational — it is controlled by `PrayerStateMachine.saveSession()` based on whether `participantName` is non-empty; no change needed there.

---
