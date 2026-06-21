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
    let mode: PhaseMode
    let displayLabel: String
    let entrySpeech: String?
    let prayers: [(utterance: String, duration: Double)]
    let exitSpeech: String?
    let motionTrigger: MotionTrigger?
    let repromptAudio: String?
    let repromptInterval: Double
    let capturesYawBaseline: Bool

    init(
        id: PrayerStateID,
        mode: PhaseMode,
        displayLabel: String,
        entrySpeech: String? = nil,
        prayers: [(utterance: String, duration: Double)] = [],
        exitSpeech: String? = nil,
        motionTrigger: MotionTrigger? = nil,
        repromptAudio: String? = nil,
        repromptInterval: Double = 8,
        capturesYawBaseline: Bool = false
    ) {
        self.id = id
        self.mode = mode
        self.displayLabel = displayLabel
        self.entrySpeech = entrySpeech
        self.prayers = prayers
        self.exitSpeech = exitSpeech
        self.motionTrigger = motionTrigger
        self.repromptAudio = repromptAudio
        self.repromptInterval = repromptInterval
        self.capturesYawBaseline = capturesYawBaseline
    }
}

// MARK: - Sequence generators

// Calibration profile
// Source: docs/calibration/master-prayer-state-machine.md
//         docs/calibration/prayers-for-each-state-in-state-machine.md
//         docs/prayers/prayers.md

enum PrayerSequenceGenerator {

    static func generate() -> [PrayerState] { masterSequence() }

    // Prayer library — resolved from docs/prayers/prayers.md
    private static let P0  = "Allah Hoo-ekber"
    private static let P1  = "Glory be to Allah the most great!"
    private static let P2  = "Glory be to Allah the most high!"
    private static let P3  = "Allah hears those who praise him."
    private static let P4  = "O Allah, all praise is due onto you."
    private static let P5  = "O Allah, forgive me."
    private static let P6  = "Peace and blessing be onto you"

    private static func masterSequence() -> [PrayerState] { [

        // Position 1
        .init(id: .qiyamStart, mode: .timed,
              displayLabel: "Standing (Qiyam) - Start",
              entrySpeech: "Start",
              prayers: [
                  ("Listen to the Ezan.", 5.0),
                  ("Give niyet", 5.0),
                  (P0, 3.0),
                  ("Al-Fatiha", 5.0),
                  (P0, 3.0),
              ]),

        // Position 2
        .init(id: .rukuFirst, mode: .motion,
              displayLabel: "Bowing (Ruku) - First",
              prayers: [
                  (P1, 1.0),
                  (P1, 1.0),
                  (P1, 3.0),
              ],
              exitSpeech: P3,
              motionTrigger: .ruku,
              repromptAudio: "Please bow into Ruku",
              repromptInterval: 5),

        // Position 3
        .init(id: .qiyamAfterRukuFirst, mode: .motion,
              displayLabel: "Standing (Qiyam) - After Ruku (Rakat 1)",
              prayers: [(P4, 3.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please return to standing",
              repromptInterval: 5),

        // Position 4
        .init(id: .sujoodFirst, mode: .motion,
              displayLabel: "Prostration (Sujood) - First",
              prayers: [
                  (P2, 1.0),
                  (P2, 1.0),
                  (P2, 1.0),
              ],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood",
              repromptInterval: 5),

        // Position 5
        .init(id: .julusFirst, mode: .motion,
              displayLabel: "Sitting (Julus) - Between Prostrations (Rakat 1)",
              prayers: [
                  (P5, 1.5),
                  (P5, 1.5),
              ],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please sit up",
              repromptInterval: 5),

        // Position 6
        .init(id: .sujoodSecond, mode: .motion,
              displayLabel: "Prostration (Sujood) - Second",
              prayers: [
                  (P2, 1.0),
                  (P2, 1.0),
                  (P2, 1.0),
              ],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood again",
              repromptInterval: 5),

        // Position 7
        .init(id: .qiyamRakat2, mode: .motion,
              displayLabel: "Standing (Qiyam) - Rakat 2",
              prayers: [("Al Fatiha", 5.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please stand for the next rakat",
              repromptInterval: 5),

        // Position 8
        .init(id: .rukuSecond, mode: .motion,
              displayLabel: "Bowing (Ruku) - Second",
              prayers: [
                  (P1, 1.0),
                  (P1, 1.0),
                  (P1, 3.0),
              ],
              exitSpeech: P3,
              motionTrigger: .ruku,
              repromptAudio: "Please bow into Ruku",
              repromptInterval: 5),

        // Position 9 — yaw baseline captured here for Tasleem
        .init(id: .qiyamAfterRukuSecond, mode: .motion,
              displayLabel: "Standing (Qiyam) - After Ruku (Rakat 2)",
              prayers: [(P4, 3.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please return to standing",
              repromptInterval: 5,
              capturesYawBaseline: true),

        // Position 10
        .init(id: .sujoodThird, mode: .motion,
              displayLabel: "Prostration (Sujood) - Third",
              prayers: [
                  (P2, 1.0),
                  (P2, 1.0),
                  (P2, 1.0),
              ],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood",
              repromptInterval: 5),

        // Position 11
        .init(id: .julusSecond, mode: .motion,
              displayLabel: "Sitting (Julus) - Between Prostrations (Rakat 2)",
              prayers: [
                  (P5, 1.5),
                  (P5, 1.5),
              ],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please sit up",
              repromptInterval: 5),

        // Position 12
        .init(id: .sujoodFourth, mode: .motion,
              displayLabel: "Prostration (Sujood) - Fourth",
              prayers: [
                  (P2, 1.0),
                  (P2, 1.0),
                  (P2, 1.0),
              ],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood again",
              repromptInterval: 5),

        // Position 13
        .init(id: .julusTashahhud, mode: .motion,
              displayLabel: "Sitting (Julus) - Tashahhud",
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
        .init(id: .tasleemRight, mode: .motion,
              displayLabel: "Tasleem - Look Right",
              prayers: [(P6, 3.0)],
              motionTrigger: .headTurnRight,
              repromptAudio: "Please turn your head to the right",
              repromptInterval: 5),

        // Position 15
        .init(id: .tasleemLeft, mode: .motion,
              displayLabel: "Tasleem - Look Left",
              prayers: [(P6, 3.0)],
              exitSpeech: "Oh Allah, you are peace and pease comes from you",
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

    // Prayer library — resolved from docs/prayers/prayers.md
    private static let P0  = "Allah Hoo-ekber"
    private static let P1  = "Glory be to Allah the most great!"
    private static let P2  = "Glory be to Allah the most high!"
    private static let P3  = "Allah hears those who praise him."
    private static let P4  = "O Allah, all praise is due onto you."
    private static let P5  = "O Allah, forgive me."
    private static let P6  = "Peace and blessing be onto you"
    private static let P7  = "All praise be to Allah, the lord of the worlds, the most compationate, the most merciful. Master of the day of judgement. You alone do we worship and you alone do we turn to for help. Guide us on the straight path, the path of those whom you have favoured and not the path of those who earn your anger, nor of those who go astray."
    private static let P8  = "All compliments, prayers and beauitiful expressions are for Allah. Please and blessing be upon you oh muhammad, and Allahs mercy and blessings. Pease be upon us, ans all righteous servants of Allah."
    private static let P9  = "Oh Allah, honor muhammad and muhammads family as you have honoured ismail and ismails family"
    private static let P10 = "Oh Allah, bless muhammad and muhammads family as you have bless ismail and ismails family"

    static func generate() -> [PrayerState] { masterSequence() }

    private static func masterSequence() -> [PrayerState] { [

        // Position 1
        .init(id: .qiyamStart, mode: .timed,
              displayLabel: "Standing (Qiyam) - Start",
              entrySpeech: "Start",
              prayers: [
                  ("Listen to the Athan.", 5.0),
                  ("Give niyet", 5.0),
                  (P0, 3.0),
                  ("Al-Fatiha", 5.0),
                  (P0, 3.0),
              ]),

        // Position 2
        .init(id: .rukuFirst, mode: .motion,
              displayLabel: "Bowing (Ruku) - First",
              prayers: [
                  (P1, 1.0),
                  (P1, 1.0),
                  (P1, 3.0),
              ],
              exitSpeech: P3,
              motionTrigger: .ruku,
              repromptAudio: "Please bow into Ruku",
              repromptInterval: 5),

        // Position 3
        .init(id: .qiyamAfterRukuFirst, mode: .motion,
              displayLabel: "Standing (Qiyam) - After Ruku (Rakat 1)",
              prayers: [(P4, 3.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please return to standing",
              repromptInterval: 5),

        // Position 4
        .init(id: .sujoodFirst, mode: .motion,
              displayLabel: "Prostration (Sujood) - First",
              prayers: [
                  (P2, 1.0),
                  (P2, 1.0),
                  (P2, 1.0),
              ],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood",
              repromptInterval: 5),

        // Position 5
        .init(id: .julusFirst, mode: .motion,
              displayLabel: "Sitting (Julus) - Between Prostrations (Rakat 1)",
              prayers: [
                  (P5, 1.5),
                  (P5, 1.5),
              ],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please sit up",
              repromptInterval: 5),

        // Position 6
        .init(id: .sujoodSecond, mode: .motion,
              displayLabel: "Prostration (Sujood) - Second",
              prayers: [
                  (P2, 1.0),
                  (P2, 1.0),
                  (P2, 1.0),
              ],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood again",
              repromptInterval: 5),

        // Position 7
        .init(id: .qiyamRakat2, mode: .motion,
              displayLabel: "Standing (Qiyam) - Rakat 2",
              prayers: [("Al Fatiha", 5.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please stand for the next rakat",
              repromptInterval: 5),

        // Position 8
        .init(id: .rukuSecond, mode: .motion,
              displayLabel: "Bowing (Ruku) - Second",
              prayers: [
                  (P1, 1.0),
                  (P1, 1.0),
                  (P1, 3.0),
              ],
              exitSpeech: P3,
              motionTrigger: .ruku,
              repromptAudio: "Please bow into Ruku",
              repromptInterval: 5),

        // Position 9 — yaw baseline captured here for Tasleem
        .init(id: .qiyamAfterRukuSecond, mode: .motion,
              displayLabel: "Standing (Qiyam) - After Ruku (Rakat 2)",
              prayers: [(P4, 3.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please return to standing",
              repromptInterval: 5,
              capturesYawBaseline: true),

        // Position 10
        .init(id: .sujoodThird, mode: .motion,
              displayLabel: "Prostration (Sujood) - Third",
              prayers: [
                  (P2, 1.0),
                  (P2, 1.0),
                  (P2, 1.0),
              ],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood",
              repromptInterval: 5),

        // Position 11
        .init(id: .julusSecond, mode: .motion,
              displayLabel: "Sitting (Julus) - Between Prostrations (Rakat 2)",
              prayers: [
                  (P5, 1.5),
                  (P5, 1.5),
              ],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please sit up",
              repromptInterval: 5),

        // Position 12
        .init(id: .sujoodFourth, mode: .motion,
              displayLabel: "Prostration (Sujood) - Fourth",
              prayers: [
                  (P2, 1.0),
                  (P2, 1.0),
                  (P2, 1.0),
              ],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood again",
              repromptInterval: 5),

        // Position 13
        .init(id: .julusTashahhud, mode: .motion,
              displayLabel: "Sitting (Julus) - Tashahhud",
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
        .init(id: .tasleemRight, mode: .motion,
              displayLabel: "Tasleem - Look Right",
              prayers: [(P6, 3.0)],
              motionTrigger: .headTurnRight,
              repromptAudio: "Please turn your head to the right",
              repromptInterval: 5),

        // Position 15
        .init(id: .tasleemLeft, mode: .motion,
              displayLabel: "Tasleem - Look Left",
              prayers: [(P6, 3.0)],
              exitSpeech: "Oh Allah, you are peace and pease comes from you",
              motionTrigger: .headTurnLeft,
              repromptAudio: "Please turn your head to the left",
              repromptInterval: 5),
    ] }
}

// MARK: - Calibration sequence
// Source: docs/calibration/prayers-for-each-state-in-state-machine.md
// No reprompts — user flows through positions silently. Entry speech plays before motion wait.

enum CalibrationSequenceGenerator {

    static func generate() -> [PrayerState] { masterSequence() }

    private static func masterSequence() -> [PrayerState] { [

        // Position 1
        .init(id: .qiyamStart, mode: .timed,
              displayLabel: "Standing (Qiyam) - Start",
              entrySpeech: "We are starting the callibration of the prayers.",
              prayers: [
                  ("The next steps will guide you through 2 Rakat's and record your movements.", 2.0),
                  ("Do not move from the position until the app instructs you with the next movement it want you to make.", 2.0),
                  ("Calibration starts in 5 seconds", 5.0),
              ]),

        // Position 2
        .init(id: .rukuFirst, mode: .motion,
              displayLabel: "Bowing (Ruku) - First",
              entrySpeech: "Bow forward and put both your hands on your knees.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .ruku),

        // Position 3
        .init(id: .qiyamAfterRukuFirst, mode: .motion,
              displayLabel: "Standing (Qiyam) - After Ruku (Rakat 1)",
              entrySpeech: "Return to standing up right position.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .upright),

        // Position 4
        .init(id: .sujoodFirst, mode: .motion,
              displayLabel: "Prostration (Sujood) - First",
              entrySpeech: "Go onto your hands and knees into a prostrating position with your forhead touching the ground.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .sujood),

        // Position 5
        .init(id: .julusFirst, mode: .motion,
              displayLabel: "Sitting (Julus) - Between Prostrations (Rakat 1)",
              entrySpeech: "Sit upright and remain seated on your knees.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .upright),

        // Position 6
        .init(id: .sujoodSecond, mode: .motion,
              displayLabel: "Prostration (Sujood) - Second",
              entrySpeech: "Go into the prostration position with your forhead touching the ground again for the second time.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .sujood),

        // Position 7
        .init(id: .qiyamRakat2, mode: .motion,
              displayLabel: "Standing (Qiyam) - Rakat 2",
              entrySpeech: "Stand up all the way straight and look forward.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .upright),

        // Position 8
        .init(id: .rukuSecond, mode: .motion,
              displayLabel: "Bowing (Ruku) - Second",
              entrySpeech: "Bow forward and put both your hands on your knees.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .ruku),

        // Position 9 — yaw baseline captured here for Tasleem detection
        .init(id: .qiyamAfterRukuSecond, mode: .motion,
              displayLabel: "Standing (Qiyam) - After Ruku (Rakat 2)",
              entrySpeech: "Return to standing up right position.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .upright,
              capturesYawBaseline: true),

        // Position 10
        .init(id: .sujoodThird, mode: .motion,
              displayLabel: "Prostration (Sujood) - Third",
              entrySpeech: "Go onto your hands and knees into a prostrating position with your forhead touching the ground.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .sujood),

        // Position 11
        .init(id: .julusSecond, mode: .motion,
              displayLabel: "Sitting (Julus) - Between Prostrations (Rakat 2)",
              entrySpeech: "Sit upright and remain seated on your knees.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .upright),

        // Position 12
        .init(id: .sujoodFourth, mode: .motion,
              displayLabel: "Prostration (Sujood) - Fourth",
              entrySpeech: "Go into the prostration position with your forhead touching the ground again for the second time.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .sujood),

        // Position 13
        .init(id: .julusTashahhud, mode: .motion,
              displayLabel: "Sitting (Julus) - Tashahhud",
              entrySpeech: "Sit upright and remain seated on your knees.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .upright),

        // Position 14
        .init(id: .tasleemRight, mode: .motion,
              displayLabel: "Tasleem - Look Right",
              entrySpeech: "Turn your head to the right.",
              prayers: [("Hold this position.", 3.0)],
              motionTrigger: .headTurnRight),

        // Position 15
        .init(id: .tasleemLeft, mode: .motion,
              displayLabel: "Tasleem - Look Left",
              entrySpeech: "Turn your head to the left.",
              prayers: [("Hold this position.", 3.0)],
              exitSpeech: "Calibration complete. You may move freely.",
              motionTrigger: .headTurnLeft),
    ] }
}
