// MARK: - Phase mode

enum PhaseMode: String {
    case auto         // speak entry, play prayers, speak exit, advance immediately
    case timed        // speak entry, play prayers with durations, speak exit
    case motion       // wait for confirmed motion, speak entry, play prayers with durations, speak exit
    case timedMotion  // speak entry, play prayers with durations (motion detection runs throughout), speak exit
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

// MARK: - State definition

struct PrayerState {
    let id: PrayerStateID
    let rakatNumber: Int
    let mode: PhaseMode
    let displayLabel: String
    let arabic: String
    let englishMeaning: String
    let entrySpeech: String?
    let prayers: [(utterance: String, duration: PrayerDuration)]
    let exitSpeech: String?
    let motionTrigger: MotionTrigger?
    let repromptAudio: String?
    let repromptInterval: Double
    let capturesYawBaseline: Bool
    let maxReprompts: Int?
    // Calibration sets this false — arc fills only during the hold phase, not motion wait.
    // Guided leaves it true (default) — arc fills during reprompt countdown as before.
    let showProgressDuringWait: Bool

    init(
        id: PrayerStateID,
        rakatNumber: Int,
        mode: PhaseMode,
        displayLabel: String,
        arabic: String,
        englishMeaning: String,
        entrySpeech: String? = nil,
        prayers: [(utterance: String, duration: PrayerDuration)] = [],
        exitSpeech: String? = nil,
        motionTrigger: MotionTrigger? = nil,
        repromptAudio: String? = nil,
        repromptInterval: Double = 8,
        capturesYawBaseline: Bool = false,
        maxReprompts: Int? = nil,
        showProgressDuringWait: Bool = true
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
        self.capturesYawBaseline = capturesYawBaseline
        self.maxReprompts = maxReprompts
        self.showProgressDuringWait = showProgressDuringWait
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

enum GuidedSequenceGenerator {

    // MARK: Public API

    static func generate(
        salat: SalatType = UserPreferences.shared.salatType,
        language: Language = UserPreferences.shared.language
    ) -> [PrayerState] {
        let tx = Tx(language: language)
        let c  = makeContent(for: salat, tx: tx)
        switch salat {
        case .fajr:
            return fajrSequence(tx: tx, c: c)
        case .maghrib:
            return maghribSequence(tx: tx, c: c)
        case .dhuhr, .asr, .isha:
            return fourRakatSequence(tx: tx, c: c)
        }
    }

    // Witr is a sunnah unit within Isha — exposed separately for future unit composition.
    static func witrSequence(language: Language = UserPreferences.shared.language) -> [PrayerState] {
        let tx = Tx(language: language)
        let c  = Content(niyetText: InstructionLibrary.text(.i25, prayer: "Witr"), hasOpeningCue: false,
                         rakat1Surah: tx.P16, rakat2Surah: tx.P17)
        let qunut: [(utterance: String, duration: PrayerDuration)] = [
            (tx.P18, .pace), (tx.P19, .pace), (tx.P20, .pace), (tx.P21, .pace), (tx.P22, .pace)
        ]
        return rakat1Full(tx: tx, c: c)
             + rakat2Full(tx: tx, c: c, capturesYaw: false)
             + shortTashahhud(tx: tx)
             + rakat3FatihaOnly(tx: tx, extraPrayers: qunut, capturesYaw: true)
             + fullTashahhud(tx: tx, rakat: 3)
             + tasleem(tx: tx, rakat: 3)
    }

    // MARK: - Prayer text bundle

    private struct Tx {
        let P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10: String
        let P11, P12, P13, P14, P15, P16, P17: String
        let P18, P19, P20, P21, P22, P23: String
        init(language: Language) {
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
        let rakat1Surah: String
        let rakat2Surah: String
    }

    private static func makeContent(for salat: SalatType, tx: Tx) -> Content {
        let niyet = InstructionLibrary.text(.i25, prayer: salat.displayName)
        switch salat {
        case .fajr:    return Content(niyetText: niyet, hasOpeningCue: true, rakat1Surah: tx.P11, rakat2Surah: tx.P12)
        case .dhuhr:   return Content(niyetText: niyet, hasOpeningCue: true, rakat1Surah: tx.P11, rakat2Surah: tx.P14)
        case .asr:     return Content(niyetText: niyet, hasOpeningCue: true, rakat1Surah: tx.P15, rakat2Surah: tx.P11)
        case .maghrib: return Content(niyetText: niyet, hasOpeningCue: true, rakat1Surah: tx.P11, rakat2Surah: tx.P13)
        case .isha:    return Content(niyetText: niyet, hasOpeningCue: true, rakat1Surah: tx.P11, rakat2Surah: tx.P12)
        }
    }

    // MARK: - Prayer sequences

    private static func fajrSequence(tx: Tx, c: Content) -> [PrayerState] {
        rakat1Full(tx: tx, c: c)
        + rakat2Full(tx: tx, c: c, capturesYaw: true)
        + fullTashahhud(tx: tx, rakat: 2)
        + tasleem(tx: tx, rakat: 2)
    }

    private static func maghribSequence(tx: Tx, c: Content) -> [PrayerState] {
        rakat1Full(tx: tx, c: c)
        + rakat2Full(tx: tx, c: c, capturesYaw: false)
        + shortTashahhud(tx: tx)
        + rakat3FatihaOnly(tx: tx, extraPrayers: [], capturesYaw: true)
        + fullTashahhud(tx: tx, rakat: 3)
        + tasleem(tx: tx, rakat: 3)
    }

    private static func fourRakatSequence(tx: Tx, c: Content) -> [PrayerState] {
        rakat1Full(tx: tx, c: c)
        + rakat2Full(tx: tx, c: c, capturesYaw: false)
        + shortTashahhud(tx: tx)
        + rakat3FatihaOnly(tx: tx, extraPrayers: [], capturesYaw: false)
        + rakat4FatihaOnly(tx: tx, capturesYaw: true)
        + fullTashahhud(tx: tx, rakat: 4)
        + tasleem(tx: tx, rakat: 4)
    }

    // MARK: - Block generators

    // RAKAT_FULL rakat 1 — timed opening (Qiyam with stand-upright cue + niyet + surahs)
    private static func rakat1Full(tx: Tx, c: Content) -> [PrayerState] {
        var openingPrayers: [(utterance: String, duration: PrayerDuration)] = []
        if c.hasOpeningCue { openingPrayers.append((InstructionLibrary.text(.i24), .fixed(5.0))) }
        openingPrayers += [
            (c.niyetText,    .fixed(5.0)),
            (tx.P0,          .fixed(3.0)),
            (tx.P7,          .fixed(2.0)),
            (c.rakat1Surah,  .fixed(2.0)),
            (tx.P0,          .fixed(2.0)),
        ]
        return [
            .init(id: .r1QiyamFull, rakatNumber: 1, mode: .timed,
                  displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
                  entrySpeech: InstructionLibrary.text(.i1),
                  prayers: openingPrayers),
            ruku(id: .r1Ruku, rakat: 1, tx: tx),
            qiyamAfterRuku(id: .r1QiyamAfterRuku, rakat: 1, tx: tx, capturesYaw: false),
            sujoodFirst(id: .r1SujoodFirst, rakat: 1, tx: tx),
            julusBetween(id: .r1JulusBetween, rakat: 1, tx: tx),
            sujoodSecond(id: .r1SujoodSecond, rakat: 1, tx: tx),
        ]
    }

    // RAKAT_FULL rakat 2 — motion (Qiyam with Fatiha + surah)
    private static func rakat2Full(tx: Tx, c: Content, capturesYaw: Bool) -> [PrayerState] {
        [
            .init(id: .r2QiyamFull, rakatNumber: 2, mode: .motion,
                  displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
                  entrySpeech: InstructionLibrary.text(.i2),
                  prayers: [(tx.P7, .pace), (c.rakat2Surah, .pace), (tx.P0, .pace)],
                  motionTrigger: .upright,
                  repromptAudio: InstructionLibrary.text(.i14),
                  repromptInterval: 5),
            ruku(id: .r2Ruku, rakat: 2, tx: tx),
            qiyamAfterRuku(id: .r2QiyamAfterRuku, rakat: 2, tx: tx, capturesYaw: capturesYaw),
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
               prayers: [(tx.P8, .pace)],
               motionTrigger: .upright,
               repromptAudio: InstructionLibrary.text(.i20),
               repromptInterval: 5)]
    }

    // RAKAT_FATIHA_ONLY rakat 3 — motion (Fatiha only, optional extra prayers for Witr Qunut)
    private static func rakat3FatihaOnly(
        tx: Tx,
        extraPrayers: [(utterance: String, duration: PrayerDuration)],
        capturesYaw: Bool
    ) -> [PrayerState] {
        var qiyamPrayers: [(utterance: String, duration: PrayerDuration)] = [(tx.P7, .pace)]
        qiyamPrayers += extraPrayers
        qiyamPrayers.append((tx.P0, .pace))
        return [
            .init(id: .r3QiyamFatiha, rakatNumber: 3, mode: .motion,
                  displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
                  entrySpeech: InstructionLibrary.text(.i10),
                  prayers: qiyamPrayers,
                  motionTrigger: .upright,
                  repromptAudio: InstructionLibrary.text(.i14),
                  repromptInterval: 5),
            ruku(id: .r3Ruku, rakat: 3, tx: tx),
            qiyamAfterRuku(id: .r3QiyamAfterRuku, rakat: 3, tx: tx, capturesYaw: capturesYaw),
            sujoodFirst(id: .r3SujoodFirst, rakat: 3, tx: tx),
            julusBetween(id: .r3JulusBetween, rakat: 3, tx: tx),
            sujoodSecond(id: .r3SujoodSecond, rakat: 3, tx: tx),
        ]
    }

    // RAKAT_FATIHA_ONLY rakat 4 — motion (Fatiha only)
    private static func rakat4FatihaOnly(tx: Tx, capturesYaw: Bool) -> [PrayerState] {
        [
            .init(id: .r4QiyamFatiha, rakatNumber: 4, mode: .motion,
                  displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
                  entrySpeech: InstructionLibrary.text(.i9),
                  prayers: [(tx.P7, .pace), (tx.P0, .pace)],
                  motionTrigger: .upright,
                  repromptAudio: InstructionLibrary.text(.i14),
                  repromptInterval: 5),
            ruku(id: .r4Ruku, rakat: 4, tx: tx),
            qiyamAfterRuku(id: .r4QiyamAfterRuku, rakat: 4, tx: tx, capturesYaw: capturesYaw),
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
               prayers: [(tx.P8, .pace), (tx.P9, .pace), (tx.P10, .pace)],
               motionTrigger: .upright,
               repromptAudio: InstructionLibrary.text(.i21),
               repromptInterval: 5)]
    }

    // TASLEEM — two head turns, closing supplication on left
    private static func tasleem(tx: Tx, rakat: Int) -> [PrayerState] {
        [
            .init(id: .tasleemRight, rakatNumber: rakat, mode: .motion,
                  displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
                  entrySpeech: InstructionLibrary.text(.i12),
                  prayers: [(tx.P6, .pace)],
                  motionTrigger: .headTurnRight,
                  repromptAudio: InstructionLibrary.text(.i22),
                  repromptInterval: 5),
            .init(id: .tasleemLeft, rakatNumber: rakat, mode: .motion,
                  displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
                  entrySpeech: InstructionLibrary.text(.i13),
                  prayers: [(tx.P6, .pace)],
                  exitSpeech: tx.P23,
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
              prayers: [(tx.P1, .pace), (tx.P1, .pace), (tx.P1, .pace)],
              exitSpeech: tx.P3,
              motionTrigger: .ruku,
              repromptAudio: InstructionLibrary.text(.i15),
              repromptInterval: 5)
    }

    private static func qiyamAfterRuku(id: PrayerStateID, rakat: Int, tx: Tx, capturesYaw: Bool) -> PrayerState {
        .init(id: id, rakatNumber: rakat, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: InstructionLibrary.text(.i4),
              prayers: [(tx.P4, .pace)],
              exitSpeech: tx.P0,
              motionTrigger: .upright,
              repromptAudio: InstructionLibrary.text(.i16),
              repromptInterval: 5,
              capturesYawBaseline: capturesYaw)
    }

    private static func sujoodFirst(id: PrayerStateID, rakat: Int, tx: Tx) -> PrayerState {
        .init(id: id, rakatNumber: rakat, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: InstructionLibrary.text(.i5),
              prayers: [(tx.P2, .pace), (tx.P2, .pace), (tx.P2, .pace)],
              exitSpeech: tx.P0,
              motionTrigger: .sujood,
              repromptAudio: InstructionLibrary.text(.i17),
              repromptInterval: 5)
    }

    private static func julusBetween(id: PrayerStateID, rakat: Int, tx: Tx) -> PrayerState {
        .init(id: id, rakatNumber: rakat, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              entrySpeech: InstructionLibrary.text(.i6),
              prayers: [(tx.P5, .pace), (tx.P5, .pace)],
              exitSpeech: tx.P0,
              motionTrigger: .upright,
              repromptAudio: InstructionLibrary.text(.i18),
              repromptInterval: 5)
    }

    private static func sujoodSecond(id: PrayerStateID, rakat: Int, tx: Tx) -> PrayerState {
        .init(id: id, rakatNumber: rakat, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: InstructionLibrary.text(.i7),
              prayers: [(tx.P2, .pace), (tx.P2, .pace), (tx.P2, .pace)],
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

    private static func masterSequence() -> [PrayerState] { [

        // Position 1 — timed: announces + holds, no motion wait
        .init(id: .r1QiyamFull, rakatNumber: 1, mode: .timed,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: "Calibration starting. You have fifteen positions to complete. Stand upright — this is Qiyam.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to bow into Ruku."),

        // Position 2
        .init(id: .r1Ruku, rakatNumber: 1, mode: .motion,
              displayLabel: "Ruku", arabic: Arabic.ruku, englishMeaning: Meaning.bowing,
              entrySpeech: "Ruku. Bow forward and place both hands on your knees.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to stand upright into Qiyam.",
              motionTrigger: .ruku,
              repromptAudio: "Bow forward and place both hands on your knees.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 3
        .init(id: .r1QiyamAfterRuku, rakatNumber: 1, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: "Qiyam. Return to standing upright.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to lower into Sujood.",
              motionTrigger: .upright,
              repromptAudio: "Stand upright.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 4
        .init(id: .r1SujoodFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: "Sujood. Lower into prostration with your forehead touching the ground.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to sit upright into Julus.",
              motionTrigger: .sujood,
              repromptAudio: "Lower into prostration with your forehead touching the ground.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 5
        .init(id: .r1JulusBetween, rakatNumber: 1, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              entrySpeech: "Julus. Sit upright on your knees.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to lower into Sujood again.",
              motionTrigger: .upright,
              repromptAudio: "Sit upright on your knees.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 6
        .init(id: .r1SujoodSecond, rakatNumber: 1, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: "Sujood. Lower into prostration again with your forehead touching the ground.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to stand upright for the second rakat.",
              motionTrigger: .sujood,
              repromptAudio: "Lower into prostration with your forehead touching the ground.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 7 — Rakat 2
        .init(id: .r2QiyamFull, rakatNumber: 2, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: "Qiyam. Stand upright for the second rakat.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to bow into Ruku.",
              motionTrigger: .upright,
              repromptAudio: "Stand upright.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 8
        .init(id: .r2Ruku, rakatNumber: 2, mode: .motion,
              displayLabel: "Ruku", arabic: Arabic.ruku, englishMeaning: Meaning.bowing,
              entrySpeech: "Ruku. Bow forward and place both hands on your knees.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to stand upright into Qiyam.",
              motionTrigger: .ruku,
              repromptAudio: "Bow forward and place both hands on your knees.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 9 — yaw baseline captured here for Tasleem detection
        .init(id: .r2QiyamAfterRuku, rakatNumber: 2, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: "Qiyam. Return to standing upright.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to lower into Sujood.",
              motionTrigger: .upright,
              repromptAudio: "Stand upright.",
              repromptInterval: 5,
              capturesYawBaseline: true, maxReprompts: 3),

        // Position 10
        .init(id: .r2SujoodFirst, rakatNumber: 2, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: "Sujood. Lower into prostration with your forehead touching the ground.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to sit upright into Julus.",
              motionTrigger: .sujood,
              repromptAudio: "Lower into prostration with your forehead touching the ground.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 11
        .init(id: .r2JulusBetween, rakatNumber: 2, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              entrySpeech: "Julus. Sit upright on your knees.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to lower into Sujood again.",
              motionTrigger: .upright,
              repromptAudio: "Sit upright on your knees.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 12
        .init(id: .r2SujoodSecond, rakatNumber: 2, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: "Sujood. Lower into prostration again with your forehead touching the ground.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to sit for Tashahhud.",
              motionTrigger: .sujood,
              repromptAudio: "Lower into prostration with your forehead touching the ground.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 13
        .init(id: .julusFull, rakatNumber: 2, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              entrySpeech: "Julus. Sit upright for Tashahhud.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to turn your head to the right for Tasleem.",
              motionTrigger: .upright,
              repromptAudio: "Sit upright on your knees.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 14
        .init(id: .tasleemRight, rakatNumber: 2, mode: .motion,
              displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
              entrySpeech: "Tasleem. Turn your head to the right.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Get ready to turn your head to the left.",
              motionTrigger: .headTurnRight,
              repromptAudio: "Turn your head to the right.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),

        // Position 15
        .init(id: .tasleemLeft, rakatNumber: 2, mode: .motion,
              displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
              entrySpeech: "Tasleem. Turn your head to the left.",
              prayers: [("Hold this position for five seconds.", .fixed(5.0))],
              exitSpeech: "Calibration complete. You may move freely.",
              motionTrigger: .headTurnLeft,
              repromptAudio: "Turn your head to the left.",
              repromptInterval: 5, maxReprompts: 3, showProgressDuringWait: false),
    ] }
}
