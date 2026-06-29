// MARK: - Phase mode

enum PhaseMode: String {
    case auto         // speak entry, play prayers, speak exit, advance immediately
    case timed        // speak entry, play prayers with durations, speak exit
    case motion       // wait for confirmed motion, speak entry, play prayers with durations, speak exit
    case timedMotion  // speak entry, play prayers with durations (motion detection runs throughout), speak exit
    // Container (Muezzin) modes — the congregational frame around the salah. Carry a `callID`
    // (C- namespace), no motionTrigger, no rakat. Exempt from Silent Mode (meant to be heard).
    // See docs/guided/CONGREGATIONAL-CONTAINER.md §4.
    case listen       // a single call/recitation, auto-paced, advances on completion (tap hatch)
    case count        // a counted dhikr — repeat to CallLibrary.count via the tasbīḥ counter (tap hatch)
}

// MARK: - Motion triggers

enum MotionTrigger: CustomStringConvertible {
    case ruku
    case sujood
    case upright       // standing or sitting — disambiguated by sequence position
    case headTurnRight
    case headTurnLeft

    var description: String {
        switch self {
        case .ruku:          return "ruku"
        case .sujood:        return "sujood"
        case .upright:       return "upright"
        case .headTurnRight: return "head turn right"
        case .headTurnLeft:  return "head turn left"
        }
    }
}

// MARK: - State IDs
// Convention from docs/guided/rakats.md: rakat{N}_{position}
// Supports up to 4 rakats (Dhuhr / Asr / Isha).

enum PrayerStateID: String {
    // Rakat 1 — RAKAT_FULL
    case r1QiyamFull
    case r1Ruku
    case r1QiyamAfterRuku
    case r1SujoodFirst
    case r1JulusBetween
    case r1SujoodSecond

    // Rakat 2 — RAKAT_FULL
    case r2QiyamFull
    case r2Ruku
    case r2QiyamAfterRuku
    case r2SujoodFirst
    case r2JulusBetween
    case r2SujoodSecond

    // SHORT_TASHAHHUD (between rakat 2 & 3 in 3+ rakat prayers)
    case julusShort

    // Rakat 3 — RAKAT_FATIHA_ONLY
    case r3QiyamFatiha
    case r3Ruku
    case r3QiyamAfterRuku
    case r3SujoodFirst
    case r3JulusBetween
    case r3SujoodSecond

    // Rakat 4 — RAKAT_FATIHA_ONLY
    case r4QiyamFatiha
    case r4Ruku
    case r4QiyamAfterRuku
    case r4SujoodFirst
    case r4JulusBetween
    case r4SujoodSecond

    // FULL_TASHAHHUD (final sitting, all prayers)
    case julusFull

    // TASLEEM (all prayers)
    case tasleemRight
    case tasleemLeft

    // CONTAINER (Muezzin frame — not a posture). The row's identity is its `callID`
    // (printed alongside in logs/snapshot); rakatNumber is 0. See CONGREGATIONAL-CONTAINER.md §4.
    case container
}

// MARK: - Prayer duration

enum PrayerDuration {
    case pace           // use UserPreferences.shared.pace.pauseDuration
    case fixed(Double)  // always this many seconds

    func seconds(pace: PrayerPace) -> Double {
        switch self {
        case .pace:         return pace.pauseDuration
        case .fixed(let d): return d
        }
    }
}

// MARK: - Prayer line
// One spoken line within a state: an optional recitation clip identity (recorded audio;
// nil = guidance/TTS-only), the rendered text (display + TTS + golden snapshot), and the
// post-utterance pause. `clipID` lets the runner play a recorded recitation when one is
// installed, falling back to TTS otherwise. See master-prayer-state-machine.md.
typealias PrayerLine = (clipID: PrayerID?, utterance: String, duration: PrayerDuration)

// A clip-less spoken line — coaching cues, niyet, calibration prompts: TTS only, never a clip.
private func spoken(_ text: String, _ duration: PrayerDuration) -> PrayerLine { (nil, text, duration) }

// MARK: - State definition

struct PrayerState {
    let id: PrayerStateID
    let rakatNumber: Int
    let mode: PhaseMode
    let displayLabel: String
    let arabic: String
    let englishMeaning: String
    let entrySpeech: String?
    let prayers: [PrayerLine]
    let exitSpeech: String?
    let motionTrigger: MotionTrigger?
    let repromptAudio: String?
    let repromptInterval: Double
    let maxReprompts: Int?
    // Calibration sets this false — arc fills only during the hold phase, not motion wait.
    // Guided leaves it true (default) — arc fills during reprompt countdown as before.
    let showProgressDuringWait: Bool
    // Unit identity within the observance — stamped by GuidedSequenceGenerator.generate.
    // Single-unit sequences (calibration, witr standalone) leave the defaults.
    var unitIndex: Int
    var unitLabel: String
    // Container (Muezzin) rows only — the C- call this row voices. Nil for in-salah rows.
    // The fiqh boundary in the type system: a container row carries a C- id, never a P-id.
    let callID: CallID?

    // A Muezzin frame row (listen/count), not an in-salah posture. Exempt from Silent Mode.
    var isContainer: Bool { mode == .listen || mode == .count }

    init(
        id: PrayerStateID,
        rakatNumber: Int,
        mode: PhaseMode,
        displayLabel: String,
        arabic: String,
        englishMeaning: String,
        entrySpeech: String? = nil,
        prayers: [PrayerLine] = [],
        exitSpeech: String? = nil,
        motionTrigger: MotionTrigger? = nil,
        repromptAudio: String? = nil,
        repromptInterval: Double = 8,
        maxReprompts: Int? = nil,
        showProgressDuringWait: Bool = true,
        unitIndex: Int = 0,
        unitLabel: String = "",
        callID: CallID? = nil
    ) {
        self.id = id
        self.rakatNumber = rakatNumber
        self.mode = mode
        self.displayLabel = displayLabel
        self.arabic = arabic
        self.englishMeaning = englishMeaning
        self.entrySpeech = entrySpeech
        self.prayers = prayers
        self.exitSpeech = exitSpeech
        self.motionTrigger = motionTrigger
        self.repromptAudio = repromptAudio
        self.repromptInterval = repromptInterval
        self.maxReprompts = maxReprompts
        self.showProgressDuringWait = showProgressDuringWait
        self.unitIndex = unitIndex
        self.unitLabel = unitLabel
        self.callID = callID
    }
}

// MARK: - Arabic / English constants

private enum Arabic {
    static let qiyam   = "قِيَام"
    static let ruku    = "رُكُوع"
    static let sujood  = "سُجُود"
    static let julus   = "جُلُوس"
    static let tasleem = "تَسْلِيم"
}

private enum Meaning {
    static let standing    = "Standing"
    static let bowing      = "Bowing"
    static let prostration = "Prostration"
    static let sitting     = "Sitting"
    static let salutation  = "Salutation"
}

// MARK: - Guided sequence
// Sources: docs/guided/master-prayer-state-machine.md
//          docs/guided/rakats.md
//          docs/guided/prayer-sets/{prayer}.md
//          docs/prayers/prayers.md

// MARK: - Prayer unit
// A unit is one complete prayer from niyet to Tasleem — the atom the generator
// builds. The canonical unit model lives in SalatType.swift (`PrayerUnit`), where
// `SalatType.units` already lists each prayer-time's full composition (built for
// prayer-setup). The guided generator consumes that model here; the observance
// layer that *chains* those units is parked (docs/guided/observance-considerations.md).
// See also the "Unit identity" section of docs/guided/master-prayer-state-machine.md.

enum GuidedSequenceGenerator {

    // MARK: Public API

    static func generate(
        salat: SalatType = UserPreferences.shared.salatType,
        language: Language = UserPreferences.shared.language,
        unitIds: Set<String> = UserPreferences.shared.selectedUnitIds,
        container: Bool = UserPreferences.shared.muezzinEnabled
    ) -> [PrayerState] {
        let tx = Tx(language: language)
        // Farḍ is always included (never stored in selectedUnitIds); sunnah/witr units
        // only when selected. Execution order is SalatType.units' order. See observances.md.
        let chain = salat.units.filter { $0.isObligatory || unitIds.contains($0.id) }
        // The Muezzin's congregational frame wraps the chain (CONGREGATIONAL-CONTAINER.md §4 +
        // container-sets/*.md): Iqāma (C-2) opens immediately before the farḍ; the boundary
        // du'ā (C-3 = P-23) marks the farḍ's exit; the dhikr + closing seal (C-4…C-11) closes
        // after the LAST unit. Ezan (C-1/C-1F) is an optional pre-roll deferred to the
        // prayer-times join (Stage 4). P-23 is now a post-salah container act, not in-salah.
        // The frame is gated by the Muezzin toggle (UserPreferences.muezzinEnabled); when off
        // the generator emits the pre-container sequence exactly — no C- rows downstream.
        let fardIndex = chain.firstIndex { $0.isObligatory }
        let lastIndex = chain.count - 1
        var states: [PrayerState] = []
        for (i, unit) in chain.enumerated() {
            if container, i == fardIndex {
                states.append(containerRow(.c2, index: i, label: unit.displayName))  // Iqāma
            }
            let unitStates = generateUnit(unit,
                                          content: content(for: salat, unit: unit, tx: tx),
                                          tx: tx,
                                          isFirst: i == 0)
            states += stamp(unitStates, index: i, label: unit.displayName)
            if container, i == fardIndex {
                states.append(containerRow(.c3, index: i, label: unit.displayName))  // boundary du'ā
            }
        }
        if container {
            states += containerSeal(index: lastIndex, label: chain.last?.displayName ?? "")
        }
        return states
    }

    // MARK: - Container (Muezzin) rows
    // A container row is a PrayerState carrying a C- callID (the fiqh boundary in the type
    // system). Mode follows the count: a repeated dhikr (>1) is `.count` (tasbīḥ counter),
    // everything else `.listen` (single recitation). Content comes from CallLibrary; nothing
    // is voiced until Stage 3. See CONGREGATIONAL-CONTAINER.md §4 and container-sets/*.md.
    private static func containerRow(_ id: CallID, index: Int, label: String) -> PrayerState {
        let mode: PhaseMode = CallLibrary.count(id) > 1 ? .count : .listen
        return PrayerState(
            id: .container,
            rakatNumber: 0,
            mode: mode,
            displayLabel: CallLibrary.name(id),
            arabic: CallLibrary.arabic(id),
            englishMeaning: CallLibrary.meaning(id),
            unitIndex: index,
            unitLabel: label,
            callID: id
        )
    }

    // The post-salah seal after the last unit, in locked order: istighfār → Āyat al-Kursī →
    // 33 · 33 · 33 → tahlīl → ṣalawāt → closing du'ā. See container-sets/fajr.md.
    private static func containerSeal(index: Int, label: String) -> [PrayerState] {
        [CallID.c4, .c5, .c6, .c7, .c8, .c9, .c10, .c11]
            .map { containerRow($0, index: index, label: label) }
    }

    // Stamps unit identity (index + label) onto every state of a unit.
    private static func stamp(_ states: [PrayerState], index: Int, label: String) -> [PrayerState] {
        states.map { var s = $0; s.unitIndex = index; s.unitLabel = label; return s }
    }

    // Standalone Witr — a single-unit observance (isFirst & isLast). NOT redundant with
    // generate(): farḍ is always force-included, so generate() can never emit Witr in
    // isolation. This is also the only coverage of the cue-less timed opener (Witr's
    // hasOpeningCue == false). Keep it. Currently exercised by the snapshot test.
    static func witrSequence(language: Language = UserPreferences.shared.language) -> [PrayerState] {
        let tx = Tx(language: language)
        let unit = PrayerUnit(id: "isha_witr", kind: .witr, rakats: 3)
        let states = generateUnit(unit, content: content(for: .isha, unit: unit, tx: tx), tx: tx,
                                  isFirst: true)
        return stamp(states, index: 0, label: unit.displayName)
    }

    // MARK: - Unit generation

    // Resolves a unit's recitation content — niyet identity + the two opening-rakat
    // surahs, both per-unit. Witr has no opening cue. See observances.md §5.
    private static func content(for salat: SalatType, unit: PrayerUnit, tx: Tx) -> Content {
        let isWitr: Bool = { if case .witr = unit.kind { return true } else { return false } }()
        let (s1, s2) = surahs(for: unit)
        return Content(
            niyetText: InstructionLibrary.text(.i25, prayer: niyetName(for: unit, salat: salat)),
            hasOpeningCue: !isWitr,
            rakat1Surah: s1,
            rakat2Surah: s2
        )
    }

    // The unit's intention, substituted into I-25 ("Give your niyet for {prayer}") so
    // each unit in a chained observance declares its own. See observances.md §5.
    private static func niyetName(for unit: PrayerUnit, salat: SalatType) -> String {
        switch unit.kind {
        case .fard:                       return "the Farḍ of \(salat.displayName)"
        case .sunnahBefore, .sunnahAfter: return "the Sunnah of \(salat.displayName)"
        case .witr:                       return "Witr"
        }
    }

    // Per-unit surahs (rakat 1, rakat 2), keyed by unit id. Every Farḍ unit opens with
    // Al-Ikhlas (P-11); Witr keeps P-16/P-17. Authoritative table: observances.md §5.
    private static func surahs(for unit: PrayerUnit) -> (PrayerID, PrayerID) {
        if case .witr = unit.kind { return (.p16, .p17) }
        switch unit.id {
        case "fajr_sb":    return (.p16, .p17)
        case "fajr_f":     return (.p11, .p13)
        case "dhuhr_sb":   return (.p14, .p12)
        case "dhuhr_f":    return (.p11, .p15)
        case "dhuhr_sa":   return (.p13, .p16)
        case "asr_sb":     return (.p17, .p12)
        case "asr_f":      return (.p11, .p14)
        case "maghrib_f":  return (.p11, .p13)
        case "maghrib_sa": return (.p17, .p16)
        case "isha_sb":    return (.p15, .p17)
        case "isha_f":     return (.p11, .p12)
        case "isha_sa":    return (.p13, .p14)
        default:           return (.p11, .p12)
        }
    }

    // True when this unit recites the Qunut dua in its final standing (Witr only).
    private static func hasQunut(_ unit: PrayerUnit) -> Bool {
        if case .witr = unit.kind { return true }
        return false
    }

    // Builds one unit's full [PrayerState]. isFirst places the unit within its observance:
    // the first unit opens with the I-1 intro (timed); a later unit opens `motion` ("stand
    // to begin"), no intro. The post-salām boundary du'ā (P-23) is no longer emitted here —
    // it is a container act (C-3), placed after the farḍ by generate(). See observances.md
    // and CONGREGATIONAL-CONTAINER.md §4. The yaw baseline is captured at runtime by the
    // phase runner at the final sitting before this unit's Tasleem — not here.
    private static func generateUnit(_ unit: PrayerUnit, content c: Content, tx: Tx,
                                     isFirst: Bool) -> [PrayerState] {
        var states = rakat1Full(tx: tx, c: c, isFirst: isFirst)
        states += rakat2Full(tx: tx, c: c)

        if unit.rakats >= 3 {
            states += shortTashahhud(tx: tx)
            let qunut: [PrayerLine] = hasQunut(unit)
                ? [tx.line(.p18, .pace), tx.line(.p19, .pace), tx.line(.p20, .pace),
                   tx.line(.p21, .pace), tx.line(.p22, .pace)]
                : []
            states += rakat3FatihaOnly(tx: tx, extraPrayers: qunut)
            if unit.rakats == 4 {
                states += rakat4FatihaOnly(tx: tx)
            }
        }

        states += fullTashahhud(tx: tx, rakat: unit.rakats)
        states += tasleem(tx: tx, rakat: unit.rakats)
        return states
    }

    // MARK: - Prayer text bundle

    private struct Tx {
        let language: Language
        let P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10: String
        let P11, P12, P13, P14, P15, P16, P17: String
        let P18, P19, P20, P21, P22, P23: String

        // A recitation line: carries the clip identity (for recorded audio) + rendered text.
        func line(_ id: PrayerID, _ duration: PrayerDuration) -> PrayerLine {
            (id, PrayerLibrary.text(id, language), duration)
        }

        init(language: Language) {
            self.language = language
            P0  = PrayerLibrary.text(.p0,  language)
            P1  = PrayerLibrary.text(.p1,  language)
            P2  = PrayerLibrary.text(.p2,  language)
            P3  = PrayerLibrary.text(.p3,  language)
            P4  = PrayerLibrary.text(.p4,  language)
            P5  = PrayerLibrary.text(.p5,  language)
            P6  = PrayerLibrary.text(.p6,  language)
            P7  = PrayerLibrary.text(.p7,  language)
            P8  = PrayerLibrary.text(.p8,  language)
            P9  = PrayerLibrary.text(.p9,  language)
            P10 = PrayerLibrary.text(.p10, language)
            P11 = PrayerLibrary.text(.p11, language)
            P12 = PrayerLibrary.text(.p12, language)
            P13 = PrayerLibrary.text(.p13, language)
            P14 = PrayerLibrary.text(.p14, language)
            P15 = PrayerLibrary.text(.p15, language)
            P16 = PrayerLibrary.text(.p16, language)
            P17 = PrayerLibrary.text(.p17, language)
            P18 = PrayerLibrary.text(.p18, language)
            P19 = PrayerLibrary.text(.p19, language)
            P20 = PrayerLibrary.text(.p20, language)
            P21 = PrayerLibrary.text(.p21, language)
            P22 = PrayerLibrary.text(.p22, language)
            P23 = PrayerLibrary.text(.p23, language)
        }
    }

    // MARK: - Per-prayer content (surahs + niyet)

    private struct Content {
        let niyetText: String
        let hasOpeningCue: Bool
        let rakat1Surah: PrayerID
        let rakat2Surah: PrayerID
    }

    // MARK: - Block generators

    // RAKAT_FULL rakat 1 — the unit's opening Qiyam.
    // isFirst: timed intro (I-1) with stand-upright cue + niyet + surahs at .fixed.
    // subsequent unit: motion "stand to begin" (I-24 entry, I-14 reprompt), renewed
    // niyet, no I-1, .pace rows. See observances.md.
    private static func rakat1Full(tx: Tx, c: Content, isFirst: Bool) -> [PrayerState] {
        let qiyam: PrayerState
        if isFirst {
            var openingPrayers: [PrayerLine] = []
            if c.hasOpeningCue { openingPrayers.append(spoken(InstructionLibrary.text(.i24), .fixed(5.0))) }
            openingPrayers += [
                spoken(c.niyetText,        .fixed(5.0)),
                tx.line(.p0,               .fixed(3.0)),
                tx.line(.p7,               .fixed(2.0)),
                tx.line(c.rakat1Surah,     .fixed(2.0)),
                tx.line(.p0,               .fixed(2.0)),
            ]
            qiyam = .init(id: .r1QiyamFull, rakatNumber: 1, mode: .timed,
                  displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
                  entrySpeech: InstructionLibrary.text(.i1),
                  prayers: openingPrayers)
        } else {
            qiyam = .init(id: .r1QiyamFull, rakatNumber: 1, mode: .motion,
                  displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
                  entrySpeech: InstructionLibrary.text(.i24),
                  prayers: [spoken(c.niyetText, .pace), tx.line(.p0, .pace), tx.line(.p7, .pace),
                            tx.line(c.rakat1Surah, .pace), tx.line(.p0, .pace)],
                  motionTrigger: .upright,
                  repromptAudio: InstructionLibrary.text(.i14),
                  repromptInterval: 5)
        }
        return [
            qiyam,
            ruku(id: .r1Ruku, rakat: 1, tx: tx),
            qiyamAfterRuku(id: .r1QiyamAfterRuku, rakat: 1, tx: tx),
            sujoodFirst(id: .r1SujoodFirst, rakat: 1, tx: tx),
            julusBetween(id: .r1JulusBetween, rakat: 1, tx: tx),
            sujoodSecond(id: .r1SujoodSecond, rakat: 1, tx: tx),
        ]
    }

    // RAKAT_FULL rakat 2 — motion (Qiyam with Fatiha + surah)
    private static func rakat2Full(tx: Tx, c: Content) -> [PrayerState] {
        [
            .init(id: .r2QiyamFull, rakatNumber: 2, mode: .motion,
                  displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
                  entrySpeech: InstructionLibrary.text(.i2),
                  prayers: [tx.line(.p7, .pace), tx.line(c.rakat2Surah, .pace), tx.line(.p0, .pace)],
                  motionTrigger: .upright,
                  repromptAudio: InstructionLibrary.text(.i14),
                  repromptInterval: 5),
            ruku(id: .r2Ruku, rakat: 2, tx: tx),
            qiyamAfterRuku(id: .r2QiyamAfterRuku, rakat: 2, tx: tx),
            sujoodFirst(id: .r2SujoodFirst, rakat: 2, tx: tx),
            julusBetween(id: .r2JulusBetween, rakat: 2, tx: tx),
            sujoodSecond(id: .r2SujoodSecond, rakat: 2, tx: tx),
        ]
    }

    // SHORT_TASHAHHUD — sits, recites Tashahhud only, then stands into rakat 3
    private static func shortTashahhud(tx: Tx) -> [PrayerState] {
        [.init(id: .julusShort, rakatNumber: 2, mode: .motion,
               displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
               entrySpeech: InstructionLibrary.text(.i8),
               prayers: [tx.line(.p8, .pace)],
               motionTrigger: .upright,
               repromptAudio: InstructionLibrary.text(.i20),
               repromptInterval: 5)]
    }

    // RAKAT_FATIHA_ONLY rakat 3 — motion (Fatiha only, optional extra prayers for Witr Qunut)
    private static func rakat3FatihaOnly(
        tx: Tx,
        extraPrayers: [PrayerLine]
    ) -> [PrayerState] {
        var qiyamPrayers: [PrayerLine] = [tx.line(.p7, .pace)]
        qiyamPrayers += extraPrayers
        qiyamPrayers.append(tx.line(.p0, .pace))
        return [
            .init(id: .r3QiyamFatiha, rakatNumber: 3, mode: .motion,
                  displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
                  entrySpeech: InstructionLibrary.text(.i10),
                  prayers: qiyamPrayers,
                  motionTrigger: .upright,
                  repromptAudio: InstructionLibrary.text(.i14),
                  repromptInterval: 5),
            ruku(id: .r3Ruku, rakat: 3, tx: tx),
            qiyamAfterRuku(id: .r3QiyamAfterRuku, rakat: 3, tx: tx),
            sujoodFirst(id: .r3SujoodFirst, rakat: 3, tx: tx),
            julusBetween(id: .r3JulusBetween, rakat: 3, tx: tx),
            sujoodSecond(id: .r3SujoodSecond, rakat: 3, tx: tx),
        ]
    }

    // RAKAT_FATIHA_ONLY rakat 4 — motion (Fatiha only)
    private static func rakat4FatihaOnly(tx: Tx) -> [PrayerState] {
        [
            .init(id: .r4QiyamFatiha, rakatNumber: 4, mode: .motion,
                  displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
                  entrySpeech: InstructionLibrary.text(.i9),
                  prayers: [tx.line(.p7, .pace), tx.line(.p0, .pace)],
                  motionTrigger: .upright,
                  repromptAudio: InstructionLibrary.text(.i14),
                  repromptInterval: 5),
            ruku(id: .r4Ruku, rakat: 4, tx: tx),
            qiyamAfterRuku(id: .r4QiyamAfterRuku, rakat: 4, tx: tx),
            sujoodFirst(id: .r4SujoodFirst, rakat: 4, tx: tx),
            julusBetween(id: .r4JulusBetween, rakat: 4, tx: tx),
            sujoodSecond(id: .r4SujoodSecond, rakat: 4, tx: tx),
        ]
    }

    // FULL_TASHAHHUD — final sitting with Tashahhud + Salawat
    private static func fullTashahhud(tx: Tx, rakat: Int) -> [PrayerState] {
        [.init(id: .julusFull, rakatNumber: rakat, mode: .motion,
               displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
               entrySpeech: InstructionLibrary.text(.i11),
               prayers: [tx.line(.p8, .pace), tx.line(.p9, .pace), tx.line(.p10, .pace)],
               motionTrigger: .upright,
               repromptAudio: InstructionLibrary.text(.i21),
               repromptInterval: 5)]
    }

    // TASLEEM — two head turns. The post-salām boundary du'ā (P-23) is no longer an in-salah
    // `exit` here; it is handed to the Muezzin as container row C-3, placed after the farḍ
    // by generate() (one source, re-voiced — not duplicated). See CONGREGATIONAL-CONTAINER.md §4.
    private static func tasleem(tx: Tx, rakat: Int) -> [PrayerState] {
        [
            .init(id: .tasleemRight, rakatNumber: rakat, mode: .motion,
                  displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
                  entrySpeech: InstructionLibrary.text(.i12),
                  prayers: [tx.line(.p6, .pace)],
                  motionTrigger: .headTurnRight,
                  repromptAudio: InstructionLibrary.text(.i22),
                  repromptInterval: 5),
            .init(id: .tasleemLeft, rakatNumber: rakat, mode: .motion,
                  displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
                  entrySpeech: InstructionLibrary.text(.i13),
                  prayers: [tx.line(.p6, .pace)],
                  motionTrigger: .headTurnLeft,
                  repromptAudio: InstructionLibrary.text(.i23),
                  repromptInterval: 5),
        ]
    }

    // MARK: - Single-state helpers (reused across blocks)

    private static func ruku(id: PrayerStateID, rakat: Int, tx: Tx) -> PrayerState {
        .init(id: id, rakatNumber: rakat, mode: .motion,
              displayLabel: "Ruku", arabic: Arabic.ruku, englishMeaning: Meaning.bowing,
              entrySpeech: InstructionLibrary.text(.i3),
              prayers: [tx.line(.p1, .pace), tx.line(.p1, .pace), tx.line(.p1, .pace)],
              exitSpeech: tx.P3,
              motionTrigger: .ruku,
              repromptAudio: InstructionLibrary.text(.i15),
              repromptInterval: 5)
    }

    private static func qiyamAfterRuku(id: PrayerStateID, rakat: Int, tx: Tx) -> PrayerState {
        .init(id: id, rakatNumber: rakat, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: InstructionLibrary.text(.i4),
              prayers: [tx.line(.p4, .pace)],
              exitSpeech: tx.P0,
              motionTrigger: .upright,
              repromptAudio: InstructionLibrary.text(.i16),
              repromptInterval: 5)
    }

    private static func sujoodFirst(id: PrayerStateID, rakat: Int, tx: Tx) -> PrayerState {
        .init(id: id, rakatNumber: rakat, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: InstructionLibrary.text(.i5),
              prayers: [tx.line(.p2, .pace), tx.line(.p2, .pace), tx.line(.p2, .pace)],
              exitSpeech: tx.P0,
              motionTrigger: .sujood,
              repromptAudio: InstructionLibrary.text(.i17),
              repromptInterval: 5)
    }

    private static func julusBetween(id: PrayerStateID, rakat: Int, tx: Tx) -> PrayerState {
        .init(id: id, rakatNumber: rakat, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              entrySpeech: InstructionLibrary.text(.i6),
              prayers: [tx.line(.p5, .pace), tx.line(.p5, .pace)],
              exitSpeech: tx.P0,
              motionTrigger: .upright,
              repromptAudio: InstructionLibrary.text(.i18),
              repromptInterval: 5)
    }

    private static func sujoodSecond(id: PrayerStateID, rakat: Int, tx: Tx) -> PrayerState {
        .init(id: id, rakatNumber: rakat, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: InstructionLibrary.text(.i7),
              prayers: [tx.line(.p2, .pace), tx.line(.p2, .pace), tx.line(.p2, .pace)],
              exitSpeech: tx.P0,
              motionTrigger: .sujood,
              repromptAudio: InstructionLibrary.text(.i19),
              repromptInterval: 5)
    }
}

// MARK: - Calibration sequence
// Source: docs/calibration/master-prayer-state-machine.md
//         docs/calibration/prayers-for-each-state-in-state-machine.md

enum CalibrationSequenceGenerator {

    static func generate() -> [PrayerState] { masterSequence() }

    private static func masterSequence() -> [PrayerState] {
        // Every position holds the same — "Hold this position for five seconds." (I-52).
        let hold = spoken(InstructionLibrary.text(.i52), .fixed(5.0))
        return [

        // Position 1 — timed: announces + holds, no motion wait
        .init(id: .r1QiyamFull, rakatNumber: 1, mode: .timed,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: InstructionLibrary.text(.i26),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i36)),

        // Position 2
        .init(id: .r1Ruku, rakatNumber: 1, mode: .motion,
              displayLabel: "Ruku", arabic: Arabic.ruku, englishMeaning: Meaning.bowing,
              entrySpeech: InstructionLibrary.text(.i27),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i37),
              motionTrigger: .ruku,
              repromptAudio: InstructionLibrary.text(.i46),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 3
        .init(id: .r1QiyamAfterRuku, rakatNumber: 1, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: InstructionLibrary.text(.i28),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i38),
              motionTrigger: .upright,
              repromptAudio: InstructionLibrary.text(.i47),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 4
        .init(id: .r1SujoodFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: InstructionLibrary.text(.i29),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i39),
              motionTrigger: .sujood,
              repromptAudio: InstructionLibrary.text(.i48),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 5
        .init(id: .r1JulusBetween, rakatNumber: 1, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              entrySpeech: InstructionLibrary.text(.i30),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i40),
              motionTrigger: .upright,
              repromptAudio: InstructionLibrary.text(.i49),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 6
        .init(id: .r1SujoodSecond, rakatNumber: 1, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: InstructionLibrary.text(.i31),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i41),
              motionTrigger: .sujood,
              repromptAudio: InstructionLibrary.text(.i48),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 7 — Rakat 2
        .init(id: .r2QiyamFull, rakatNumber: 2, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: InstructionLibrary.text(.i32),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i36),
              motionTrigger: .upright,
              repromptAudio: InstructionLibrary.text(.i47),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 8
        .init(id: .r2Ruku, rakatNumber: 2, mode: .motion,
              displayLabel: "Ruku", arabic: Arabic.ruku, englishMeaning: Meaning.bowing,
              entrySpeech: InstructionLibrary.text(.i27),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i37),
              motionTrigger: .ruku,
              repromptAudio: InstructionLibrary.text(.i46),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 9 — yaw baseline captured here for Tasleem detection
        .init(id: .r2QiyamAfterRuku, rakatNumber: 2, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: InstructionLibrary.text(.i28),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i38),
              motionTrigger: .upright,
              repromptAudio: InstructionLibrary.text(.i47),
              repromptInterval: 5,
              maxReprompts: 3),

        // Position 10
        .init(id: .r2SujoodFirst, rakatNumber: 2, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: InstructionLibrary.text(.i29),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i39),
              motionTrigger: .sujood,
              repromptAudio: InstructionLibrary.text(.i48),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 11
        .init(id: .r2JulusBetween, rakatNumber: 2, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              entrySpeech: InstructionLibrary.text(.i30),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i40),
              motionTrigger: .upright,
              repromptAudio: InstructionLibrary.text(.i49),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 12
        .init(id: .r2SujoodSecond, rakatNumber: 2, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: InstructionLibrary.text(.i31),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i42),
              motionTrigger: .sujood,
              repromptAudio: InstructionLibrary.text(.i48),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 13
        .init(id: .julusFull, rakatNumber: 2, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              entrySpeech: InstructionLibrary.text(.i33),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i43),
              motionTrigger: .upright,
              repromptAudio: InstructionLibrary.text(.i49),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 14
        .init(id: .tasleemRight, rakatNumber: 2, mode: .motion,
              displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
              entrySpeech: InstructionLibrary.text(.i34),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i44),
              motionTrigger: .headTurnRight,
              repromptAudio: InstructionLibrary.text(.i50),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 15
        .init(id: .tasleemLeft, rakatNumber: 2, mode: .motion,
              displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
              entrySpeech: InstructionLibrary.text(.i35),
              prayers: [hold],
              exitSpeech: InstructionLibrary.text(.i45),
              motionTrigger: .headTurnLeft,
              repromptAudio: InstructionLibrary.text(.i51),
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),
    ] }
}
