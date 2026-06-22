import Foundation

// Source: docs/prayers/prayers.md
// All three language columns are kept here as the single Swift source of truth.

enum PrayerID: String {
    case p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10
}

enum PrayerLibrary {

    static func text(_ id: PrayerID, _ language: Language) -> String {
        switch id {
        case .p0:
            switch language {
            case .arabic:  return "اللهُ أَكْبَر"
            case .turkish: return "Allahu Ekber"
            case .english: return "Allah is the Greatest"
            }
        case .p1:
            switch language {
            case .arabic:  return "سُبْحَانَ رَبِّيَ الْعَظِيم"
            case .turkish: return "Sübhane Rabbiyel Azîm"
            case .english: return "Glory be to Allah the most great"
            }
        case .p2:
            switch language {
            case .arabic:  return "سُبْحَانَ رَبِّيَ الْأَعْلَى"
            case .turkish: return "Sübhane Rabbiyel A'lâ"
            case .english: return "Glory be to Allah the most high"
            }
        case .p3:
            switch language {
            case .arabic:  return "سَمِعَ اللهُ لِمَنْ حَمِدَهُ"
            case .turkish: return "Semi Allahu limen hamideh"
            case .english: return "Allah hears those who praise him"
            }
        case .p4:
            switch language {
            case .arabic:  return "رَبَّنَا وَلَكَ الْحَمْد"
            case .turkish: return "Rabbena ve lekel hamd"
            case .english: return "O Allah, all praise is due to you"
            }
        case .p5:
            switch language {
            case .arabic:  return "رَبِّ اغْفِرْ لِي"
            case .turkish: return "Rabbigfir li"
            case .english: return "O Allah, forgive me"
            }
        case .p6:
            switch language {
            case .arabic:  return "السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ"
            case .turkish: return "Es-selamu aleykum ve rahmetullah"
            case .english: return "Peace and blessings be upon you"
            }
        case .p7:
            switch language {
            case .arabic:  return "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ الرَّحْمَٰنِ الرَّحِيمِ مَالِكِ يَوْمِ الدِّينِ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ"
            case .turkish: return "Elhamdülillahi rabbil alemin. Errahmanirrahim. Maliki yevmiddin. İyyake na'büdü ve iyyake nestein. İhdinas sıratal müstakim. Sıratalleziyne en'amte aleyhim. Ğayril mağdubi aleyhim ve laddâllin."
            case .english: return "All praise be to Allah, the lord of the worlds, the most compassionate, the most merciful. Master of the day of judgement. You alone do we worship and you alone do we turn to for help. Guide us on the straight path, the path of those whom you have favoured, not the path of those who earn your anger, nor of those who go astray."
            }
        case .p8:
            switch language {
            case .arabic:  return "التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ"
            case .turkish: return "Ettehiyyatü lillahi vesselavatü vettayyibat. Es-selamü aleyke eyyühen nebiyyü ve rahmetullahi ve berekatüh. Es-selamü aleyna ve ala ibadillahis salihin. Eşhedü en la ilahe illallah ve eşhedü enne Muhammeden abdühu ve resulüh."
            case .english: return "All compliments, prayers and beautiful expressions are for Allah. Peace and blessings be upon you O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon all righteous servants of Allah. I bear witness that there is no god but Allah and I bear witness that Muhammad is His servant and messenger."
            }
        case .p9:
            switch language {
            case .arabic:  return "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ"
            case .turkish: return "Allahümme salli ala Muhammedin ve ala ali Muhammed. Kema salleyte ala İbrahime ve ala ali İbrahim. İnneke hamidun mecid."
            case .english: return "O Allah, honour Muhammad and the family of Muhammad as you have honoured Ibrahim and the family of Ibrahim. Indeed you are praiseworthy and glorious."
            }
        case .p10:
            switch language {
            case .arabic:  return "اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ"
            case .turkish: return "Allahümme barik ala Muhammedin ve ala ali Muhammed. Kema barekte ala İbrahime ve ala ali İbrahim. İnneke hamidun mecid."
            case .english: return "O Allah, bless Muhammad and the family of Muhammad as you have blessed Ibrahim and the family of Ibrahim. Indeed you are praiseworthy and glorious."
            }
        }
    }
}
