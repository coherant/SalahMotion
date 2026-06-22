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

// MARK: - State IDs (15-phase master sequence)

enum PrayerStateID: String {
    case qiyamStart
    case rukuFirst
    case qiyamAfterRukuFirst
    case sujoodFirst
    case julusFirst
    case sujoodSecond
    case qiyamRakat2
    case rukuSecond
    case qiyamAfterRukuSecond
    case sujoodThird
    case julusSecond
    case sujoodFourth
    case julusTashahhud
    case tasleemRight
    case tasleemLeft
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
    let prayers: [(utterance: String, duration: Double)]
    let exitSpeech: String?
    let motionTrigger: MotionTrigger?
    let repromptAudio: String?
    let repromptInterval: Double
    let capturesYawBaseline: Bool

    init(
        id: PrayerStateID,
        rakatNumber: Int,
        mode: PhaseMode,
        displayLabel: String,
        arabic: String,
        englishMeaning: String,
        entrySpeech: String? = nil,
        prayers: [(utterance: String, duration: Double)] = [],
        exitSpeech: String? = nil,
        motionTrigger: MotionTrigger? = nil,
        repromptAudio: String? = nil,
        repromptInterval: Double = 8,
        capturesYawBaseline: Bool = false
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
    }
}

// MARK: - Arabic / English constants (source: master-prayer-state-machine.md)

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

// MARK: - Sequence generators

// Calibration profile
// Source: docs/calibration/master-prayer-state-machine.md
//         docs/calibration/prayers-for-each-state-in-state-machine.md
//         docs/prayers/prayers.md

enum PrayerSequenceGenerator {

    static func generate() -> [PrayerState] { masterSequence() }

    private static let P0  = "Allah Hoo-ekber"
    private static let P1  = "Glory be to Allah the most great!"
    private static let P2  = "Glory be to Allah the most high!"
    private static let P3  = "Allah hears those who praise him."
    private static let P4  = "O Allah, all praise is due onto you."
    private static let P5  = "O Allah, forgive me."
    private static let P6  = "Peace and blessing be onto you"

    private static func masterSequence() -> [PrayerState] { [

        // Position 1 — Rakat 1
        .init(id: .qiyamStart, rakatNumber: 1, mode: .timed,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: "Start",
              prayers: [
                  ("Listen to the Ezan.", 5.0),
                  ("Give niyet", 5.0),
                  (P0, 3.0),
                  ("Al-Fatiha", 5.0),
                  (P0, 3.0),
              ]),

        // Position 2
        .init(id: .rukuFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Ruku", arabic: Arabic.ruku, englishMeaning: Meaning.bowing,
              prayers: [(P1, 1.0), (P1, 1.0), (P1, 3.0)],
              exitSpeech: P3,
              motionTrigger: .ruku,
              repromptAudio: "Please bow into Ruku",
              repromptInterval: 5),

        // Position 3
        .init(id: .qiyamAfterRukuFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              prayers: [(P4, 3.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please return to standing",
              repromptInterval: 5),

        // Position 4
        .init(id: .sujoodFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              prayers: [(P2, 1.0), (P2, 1.0), (P2, 1.0)],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood",
              repromptInterval: 5),

        // Position 5
        .init(id: .julusFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              prayers: [(P5, 1.5), (P5, 1.5)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please sit up",
              repromptInterval: 5),

        // Position 6
        .init(id: .sujoodSecond, rakatNumber: 1, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              prayers: [(P2, 1.0), (P2, 1.0), (P2, 1.0)],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood again",
              repromptInterval: 5),

        // Position 7 — Rakat 2
        .init(id: .qiyamRakat2, rakatNumber: 2, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              prayers: [("Al Fatiha", 5.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please stand for the next rakat",
              repromptInterval: 5),

        // Position 8
        .init(id: .rukuSecond, rakatNumber: 2, mode: .motion,
              displayLabel: "Ruku", arabic: Arabic.ruku, englishMeaning: Meaning.bowing,
              prayers: [(P1, 1.0), (P1, 1.0), (P1, 3.0)],
              exitSpeech: P3,
              motionTrigger: .ruku,
              repromptAudio: "Please bow into Ruku",
              repromptInterval: 5),

        // Position 9 — yaw baseline captured here for Tasleem
        .init(id: .qiyamAfterRukuSecond, rakatNumber: 2, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              prayers: [(P4, 3.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please return to standing",
              repromptInterval: 5,
              capturesYawBaseline: true),

        // Position 10
        .init(id: .sujoodThird, rakatNumber: 2, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              prayers: [(P2, 1.0), (P2, 1.0), (P2, 1.0)],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood",
              repromptInterval: 5),

        // Position 11
        .init(id: .julusSecond, rakatNumber: 2, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              prayers: [(P5, 1.5), (P5, 1.5)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please sit up",
              repromptInterval: 5),

        // Position 12
        .init(id: .sujoodFourth, rakatNumber: 2, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              prayers: [(P2, 1.0), (P2, 1.0), (P2, 1.0)],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood again",
              repromptInterval: 5),

        // Position 13
        .init(id: .julusTashahhud, rakatNumber: 2, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              prayers: [
                  ("Tashahhud", 2.0),
                  ("Honour Muhammad", 2.0),
                  ("Bless Muhammad", 2.0),
                  ("Grant me the good of this world", 2.0),
                  ("Forgive me and my parents", 2.0),
                  ("Ive greatly wronged myself", 2.0),
              ],
              motionTrigger: .upright,
              repromptAudio: "Please sit for Tashahhud",
              repromptInterval: 5),

        // Position 14
        .init(id: .tasleemRight, rakatNumber: 2, mode: .motion,
              displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
              prayers: [(P6, 3.0)],
              motionTrigger: .headTurnRight,
              repromptAudio: "Please turn your head to the right",
              repromptInterval: 5),

        // Position 15
        .init(id: .tasleemLeft, rakatNumber: 2, mode: .motion,
              displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
              prayers: [(P6, 3.0)],
              exitSpeech: "Oh Allah, you are peace and peace comes from you",
              motionTrigger: .headTurnLeft,
              repromptAudio: "Please turn your head to the left",
              repromptInterval: 5),
    ] }
}

// Guided profile
// Source: docs/guided/master-prayer-state-machine.md
//         docs/guided/prayers-for-each-state-in-state-machine.md
//         docs/prayers/prayers.md

enum GuidedSequenceGenerator {

    static func generate(language: Language = UserPreferences.shared.language) -> [PrayerState] {
        masterSequence(language: language)
    }

    private static func masterSequence(language: Language) -> [PrayerState] {
        let P0 = PrayerLibrary.text(.p0, language)
        let P1 = PrayerLibrary.text(.p1, language)
        let P2 = PrayerLibrary.text(.p2, language)
        let P3 = PrayerLibrary.text(.p3, language)
        let P4 = PrayerLibrary.text(.p4, language)
        let P5 = PrayerLibrary.text(.p5, language)
        let P6 = PrayerLibrary.text(.p6, language)
        return [

        // Position 1 — Rakat 1
        .init(id: .qiyamStart, rakatNumber: 1, mode: .timed,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: "Start",
              prayers: [
                  ("Listen to the Athan.", 5.0),
                  ("Give niyet", 5.0),
                  (P0, 3.0),
                  ("Al-Fatiha", 5.0),
                  (P0, 3.0),
              ]),

        // Position 2
        .init(id: .rukuFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Ruku", arabic: Arabic.ruku, englishMeaning: Meaning.bowing,
              prayers: [(P1, 1.0), (P1, 1.0), (P1, 3.0)],
              exitSpeech: P3,
              motionTrigger: .ruku,
              repromptAudio: "Please bow into Ruku",
              repromptInterval: 5),

        // Position 3
        .init(id: .qiyamAfterRukuFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              prayers: [(P4, 3.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please return to standing",
              repromptInterval: 5),

        // Position 4
        .init(id: .sujoodFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              prayers: [(P2, 1.0), (P2, 1.0), (P2, 1.0)],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood",
              repromptInterval: 5),

        // Position 5
        .init(id: .julusFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              prayers: [(P5, 1.5), (P5, 1.5)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please sit up",
              repromptInterval: 5),

        // Position 6
        .init(id: .sujoodSecond, rakatNumber: 1, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              prayers: [(P2, 1.0), (P2, 1.0), (P2, 1.0)],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood again",
              repromptInterval: 5),

        // Position 7 — Rakat 2
        .init(id: .qiyamRakat2, rakatNumber: 2, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              prayers: [("Al Fatiha", 5.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please stand for the next rakat",
              repromptInterval: 5),

        // Position 8
        .init(id: .rukuSecond, rakatNumber: 2, mode: .motion,
              displayLabel: "Ruku", arabic: Arabic.ruku, englishMeaning: Meaning.bowing,
              prayers: [(P1, 1.0), (P1, 1.0), (P1, 3.0)],
              exitSpeech: P3,
              motionTrigger: .ruku,
              repromptAudio: "Please bow into Ruku",
              repromptInterval: 5),

        // Position 9 — yaw baseline captured here for Tasleem
        .init(id: .qiyamAfterRukuSecond, rakatNumber: 2, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              prayers: [(P4, 3.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please return to standing",
              repromptInterval: 5,
              capturesYawBaseline: true),

        // Position 10
        .init(id: .sujoodThird, rakatNumber: 2, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              prayers: [(P2, 1.0), (P2, 1.0), (P2, 1.0)],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood",
              repromptInterval: 5),

        // Position 11
        .init(id: .julusSecond, rakatNumber: 2, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              prayers: [(P5, 1.5), (P5, 1.5)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please sit up",
              repromptInterval: 5),

        // Position 12
        .init(id: .sujoodFourth, rakatNumber: 2, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              prayers: [(P2, 1.0), (P2, 1.0), (P2, 1.0)],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood again",
              repromptInterval: 5),

        // Position 13
        .init(id: .julusTashahhud, rakatNumber: 2, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              prayers: [
                  ("Tashahhud", 2.0),
                  ("Honour Muhammad", 2.0),
                  ("Bless Muhammad", 2.0),
                  ("Grant me the good of this world", 2.0),
                  ("Forgive me and my parents", 2.0),
                  ("Ive greatly wronged myself", 2.0),
              ],
              motionTrigger: .upright,
              repromptAudio: "Please sit for Tashahhud",
              repromptInterval: 5),

        // Position 14
        .init(id: .tasleemRight, rakatNumber: 2, mode: .motion,
              displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
              prayers: [(P6, 3.0)],
              motionTrigger: .headTurnRight,
              repromptAudio: "Please turn your head to the right",
              repromptInterval: 5),

        // Position 15
        .init(id: .tasleemLeft, rakatNumber: 2, mode: .motion,
              displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
              prayers: [(P6, 3.0)],
              exitSpeech: "Oh Allah, you are peace and peace comes from you",
              motionTrigger: .headTurnLeft,
              repromptAudio: "Please turn your head to the left",
              repromptInterval: 5),
        ]
    }
}

// MARK: - Calibration sequence
// Source: docs/calibration/master-prayer-state-machine.md
// No reprompts — user flows through positions silently. Entry speech plays before motion wait.

enum CalibrationSequenceGenerator {

    static func generate() -> [PrayerState] { masterSequence() }

    private static func masterSequence() -> [PrayerState] { [

        // Position 1 — Rakat 1
        .init(id: .qiyamStart, rakatNumber: 1, mode: .timed,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: "We are starting the calibration of the prayers.",
              prayers: [
                  ("The next steps will guide you through 2 Rakats and record your movements.", 2.0),
                  ("Do not move from the position until the app instructs you with the next movement.", 2.0),
                  ("Calibration starts in 5 seconds", 5.0),
              ]),

        // Position 2
        .init(id: .rukuFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Ruku", arabic: Arabic.ruku, englishMeaning: Meaning.bowing,
              entrySpeech: "Bow forward and put both your hands on your knees.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .ruku),

        // Position 3
        .init(id: .qiyamAfterRukuFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: "Return to standing upright position.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .upright),

        // Position 4
        .init(id: .sujoodFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: "Go onto your hands and knees into a prostrating position with your forehead touching the ground.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .sujood),

        // Position 5
        .init(id: .julusFirst, rakatNumber: 1, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              entrySpeech: "Sit upright and remain seated on your knees.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .upright),

        // Position 6
        .init(id: .sujoodSecond, rakatNumber: 1, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: "Go into the prostration position with your forehead touching the ground again.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .sujood),

        // Position 7 — Rakat 2
        .init(id: .qiyamRakat2, rakatNumber: 2, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: "Stand up all the way straight and look forward.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .upright),

        // Position 8
        .init(id: .rukuSecond, rakatNumber: 2, mode: .motion,
              displayLabel: "Ruku", arabic: Arabic.ruku, englishMeaning: Meaning.bowing,
              entrySpeech: "Bow forward and put both your hands on your knees.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .ruku),

        // Position 9 — yaw baseline captured here for Tasleem detection
        .init(id: .qiyamAfterRukuSecond, rakatNumber: 2, mode: .motion,
              displayLabel: "Qiyam", arabic: Arabic.qiyam, englishMeaning: Meaning.standing,
              entrySpeech: "Return to standing upright position.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .upright,
              capturesYawBaseline: true),

        // Position 10
        .init(id: .sujoodThird, rakatNumber: 2, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: "Go onto your hands and knees into a prostrating position with your forehead touching the ground.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .sujood),

        // Position 11
        .init(id: .julusSecond, rakatNumber: 2, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              entrySpeech: "Sit upright and remain seated on your knees.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .upright),

        // Position 12
        .init(id: .sujoodFourth, rakatNumber: 2, mode: .motion,
              displayLabel: "Sujood", arabic: Arabic.sujood, englishMeaning: Meaning.prostration,
              entrySpeech: "Go into the prostration position with your forehead touching the ground again.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .sujood),

        // Position 13
        .init(id: .julusTashahhud, rakatNumber: 2, mode: .motion,
              displayLabel: "Julus", arabic: Arabic.julus, englishMeaning: Meaning.sitting,
              entrySpeech: "Sit upright and remain seated on your knees.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .upright),

        // Position 14
        .init(id: .tasleemRight, rakatNumber: 2, mode: .motion,
              displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
              entrySpeech: "Turn your head to the right.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .headTurnRight),

        // Position 15
        .init(id: .tasleemLeft, rakatNumber: 2, mode: .motion,
              displayLabel: "Tasleem", arabic: Arabic.tasleem, englishMeaning: Meaning.salutation,
              entrySpeech: "Turn your head to the left.",
              prayers: [("Hold this position.", 3.0)],
              exitSpeech: "Calibration complete. You may move freely.",
              motionTrigger: .headTurnLeft),
    ] }
}
