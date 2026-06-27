# App Settings — Feature Spec

Source of truth for the **Settings** screen.
Use this file to define layout, components, interactions, and data before building.

## 0. Overview

This is the settings for the entire application.

**Status:** Built as a themed **master/detail flow** (`SettingsView` + `SettingsViewModel`
+ `SettingsComponents`, reachable as the 5th tab). Matches the dark, prayer-accented
design in `settings.html`. Backed by `PrayerCalculationSettings`, `UserPreferences`,
and `NotificationManager`, all feeding the Adhan-based `PrayerTimesEngine`.

Items are annotated **[BUILT]** (wired to a real backend) or _(UI present — not wired)_:
the control is rendered to match the mockup and its selection persists locally, but it
does not yet affect the engine/audio. Those need a product decision or extra
infrastructure before wiring.

---

## 1. Layout

Reference mockup: `docs/features/settings/settings.html` (a bundled JS prototype;
decode the base64-gzip manifest to read the markup).

Three screens, one at a time, switched by `SettingsViewModel.screen`
(`main` / `alerts` / `advanced`) with a cross-fade:

- **Main** — header "PREFERENCES / Settings" + two accent-tinted nav cards
  (icon tile · title · subtitle · chevron): "Prayer Alerts" → alerts screen,
  "Advanced" → advanced screen.
- **Prayer Alerts** — header "NOTIFICATIONS / Prayer Alerts", back chevron.
- **Advanced** — header "CONFIGURATION / Advanced", back chevron.
- **Muezzin** - header "MUEZZIN" / Muezzin Settings", back chevron.

**Theme** (fixed dark palette; see `SettingsPalette`):
- Background gradient `#1a1730 → #131120 → #100e1b`.
- Ink `#f4f1fa`, muted `#b8b2c8`, faint `#847e98`.
- **Accent** = the current prayer's accent (`PrayerTime.current.theme.accent`)
  for global chrome (header eyebrow, main cards, Suhoor/Qiyam toggles, language,
  rate). **Per-prayer rows** use that prayer's own accent
  (`PrayerTime.theme.accent`), which matches the mockup's hex values exactly.
- Fonts via `Typography`: `display` (titles 28), `ui` (body), `arabic` (RTL).

**Reusable controls** (`SettingsComponents.swift`): `SettingsSectionLabel`
(eyebrow), `.settingsCard()`, `SettingsChevron` (rotates on expand),
`SettingsToggle` (44×26 pill), `SettingsRadio` (20pt ring), `SettingsStepper`
(circular −/＋ + value), `SettingsOptionRow` (radio + label/detail/Arabic).

---

## 2. Settings sections

# Prayer Alerts
DESCRIPTION: Notifcations setting for all prayers -> A common screen which gives the user the ability to select the different recitation for each prayer 

Layout and taxonomy of settings
-[setting] Sahoor ending reminder (on/off) -> used in the month of ramadan and is used to alert (via notification) 15 mins before sahoor. **[BUILT]** — fires 15 min before Fajr, repeating daily.
-[list] For each Prayer (e.g. Fajr, Asr etc) — an expandable card; the name + Arabic show, with an "ON" tag when alerts are enabled.
    --[option] Pre-Adhan reminder (on/off) **[BUILT, partial]** — this toggle is wired to the real per-prayer alert, which currently fires *at* the prayer time. The mockup copy ("30 minutes before") is shown as-is; the 30-min-before timing is _(deferred)_ and needs a second scheduled notification per prayer.
    --[list] Recitation — radio list of 6 reciters (Mishary, Sudais, Minshawi, Hussary, Ghamdi, Shuraym) _(UI present — not wired)_. Selection persists per prayer (`settings.reciters`) but drives no audio yet; needs a recitation/audio data model + custom notification sounds. `UserPreferences.muezzinId` is the guided-prayer reciter only.
        ---[item] Recitation audio file

# Advanced
DESCRIPTION: Prayer time adjustments off the master prayer times table 
-[list] Prayer names (e.g. Fajr)
    --[list-item] Fajr **[BUILT]** (`FajrRule`)
        Decription: only onne is selectable
        [setting] Normal > use the master time
        [setting] 1.5 hours before sunrise
    --[list-item] Sunrise _(UI present — not wired)_ — radio shown (Normal / Doha); selection persists (`settings.sunriseDoha`) but does not yet affect computed times. Sunrise is not a listed prayer (only the 5 daily prayers render); where "Doha" surfaces needs a product decision.
        Decription: only onne is selectable
        [setting] Normal > use the master time
        [setting] Doha
    --[list-item] Asr **[BUILT]** (`Madhab`)
        Decription: only onne is selectable
        [setting] Standard (Shafi, Maliki, Hanbali)
        [setting] Hanafi
    --[list-item] Isha _(UI present — not wired)_ — radio shown (Normal / 1.5 hrs / 2 hrs before Maghrib); selection persists (`settings.ishaRule`) but does not yet affect computed times. NOTE: "before Maghrib" is physically impossible (Isha is after Maghrib); the wording mirrors the mockup and likely means "after". Needs clarification, then maps to Adhan's `ishaInterval`.
        Decription: only onne is selectable
        [setting] Normal > use the master time
        [setting] 1.5 hours before Maghrib
        [setting] 2 hours before Maghrib
    --[list-item] Qiyam (on/off) _(UI present — not wired)_ — toggle shown; selection persists (`settings.qiyamOn`). Engine already computes Qiyam (last third of night), but adding it to the Prayer Times list needs a list-render change + its own theme. --> this adds the Qiyam time to the list of prayers on the Prayer Times Screen at the end of the prayers list.
-[setting] Prayer Time Adjustments
    --[list-item] Fajr
        Decription: scrollable wheel default = 0
        [setting] offset
    --[list-item] Dhuhr
        Decription: scrollable wheel default = 0
        [setting] offset
    --[list-item] Asr
        Decription: scrollable wheel default = 0
        [setting] offset
    --[list-item] Maghrib
        Decription: scrollable wheel default = 0
        [setting] offset
    --[list-item] Isha
        Decription: scrollable wheel default = 0
        [setting] offset
    Note: built as ±30 min Steppers per prayer (not scrollable wheels).
-[setting] Adjust Hijri Days **[BUILT]** (±3 days, Stepper)
    Decription: scrollable wheel default = 0
    [setting] offset
-[setting] Language **[BUILT]** — bound to `UserPreferences.language`
    -[list] Languages (the 3 the app actually localises)
        --[list-item] English (default)
        --[list-item] Turkish
        --[list-item] Arabic
-[function] Rate this app **[BUILT]** -> Connects to the apple ratings system (`SKStoreReviewController`)

# Muezzin
-[setting] Langage to display in prayer session
    - [setting] Arabic
    - [setting] English
    - [setting] Turkish


## Prayer Calculation Method
DESCRIPTION: Prayer time calculation method **[BUILT]** — bound to `PrayerCalculationSettings.method`
-[list] All the popular calculation methods (the picker offers every Adhan method, not just these three)
    --[list-item] Muslim world league
    --[list-item] Egypitan general authority
    --[list-item] Islamic University, Karachi

NOTE: the `settings.html` mockup does **not** include this global method picker
(only the per-prayer methods above). Because it is real, wired, and drives the
engine, it is shown as the **first expandable row** in Advanced → "Prayer Methods"
(labelled "Calculation"), styled identically to the other method rows. Remove it if
strict mockup fidelity is preferred.


---

## 3. States

- **Default:** Main screen; no expandable rows open.
- Per-prayer alert rows and Advanced method rows are **collapsed by default**;
  only one alert row and one method row can be expanded at a time.
- No loading/empty/error states — all settings read from local persisted stores.

---

## 4. Interactions

- **Navigation:** tapping a Main nav card cross-fades to that sub-screen; the
  header back chevron returns to Main (and collapses any open rows).
- **Toggles** (`SettingsToggle`): tap anywhere on the pill to flip; animates the thumb.
- **Expandable rows** (alerts / methods): tap the header to expand/collapse; the
  chevron rotates 90°. Selecting a method option collapses the row.
- **Radios** (`SettingsOptionRow`, language): single-select; tap to choose.
- **Steppers** (`SettingsStepper`): −/＋ buttons; offsets clamp to ±30 min,
  Hijri to ±3 days.
- **Rate:** triggers `SKStoreReviewController.requestReview`.

---

## 5. Data model

Persisted via `@Observable` singletons (each property writes through to UserDefaults
in `didSet`); the engine recomputes whenever a calculation input changes.

| Setting | Owner | UserDefaults key |
| --- | --- | --- |
| Calculation method | `PrayerCalculationSettings.method` | `prayerCalc.method` |
| Fajr rule | `PrayerCalculationSettings.fajrRule` | `prayerCalc.fajrRule` |
| Asr madhab | `PrayerCalculationSettings.madhab` | `prayerCalc.madhab` |
| Per-prayer offsets | `PrayerCalculationSettings.offsets` | `prayerCalc.offsets` |
| Hijri day offset | `PrayerCalculationSettings.hijriOffsetDays` | `prayerCalc.hijriOffsetDays` |
| Language | `UserPreferences.language` | `selectedPrayerLanguage` |
| Per-prayer alerts | `NotificationManager` | `notifications.enabledPrayers` |
| Suhoor reminder | `NotificationManager` | `notifications.suhoorReminder` |

UI-only state (persisted by `SettingsViewModel`, not yet wired to engine/audio):

| Setting | Owner | UserDefaults key |
| --- | --- | --- |
| Sunrise (Normal/Doha) | `SettingsViewModel.sunriseDoha` | `settings.sunriseDoha` |
| Isha rule | `SettingsViewModel.ishaRule` | `settings.ishaRule` |
| Qiyam in list | `SettingsViewModel.qiyamOn` | `settings.qiyamOn` |
| Per-prayer reciter | `SettingsViewModel.reciters` | `settings.reciters` |

---

## 6. Navigation

Reached as the 5th tab ("Settings", `gearshape.fill`) in `AppShell`'s `TabView`
(`AppTab.settings`). Inside, navigation is a self-contained master/detail flow
driven by `SettingsViewModel.screen` (`main` → `alerts` / `advanced`) with a custom
themed header and back chevron — not a system `NavigationStack`/`Form`. Controls
edit in place; deeper detail (per-prayer recitation, per-prayer methods) lives in
expandable rows within the sub-screens.
