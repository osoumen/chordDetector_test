import Foundation

class ChordRecognizer {
    private let enabledChordTypes: [ChordType]
    private let useFlats: Bool
    
    private static let sharpNoteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    private static let flatNoteNames = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
    
    init(enabledChordTypes: [ChordType], useFlats: Bool) {
        self.enabledChordTypes = enabledChordTypes
        self.useFlats = useFlats
    }
    
    func recognizeChord(from notes: Set<Int>) -> (bestRootPitchClass: Int, bestChordType: ChordType, lowestNotePitchClass: Int) {
        guard !notes.isEmpty else { return (-1, ChordType.major, -1) }
        guard !enabledChordTypes.isEmpty else { return (-1, ChordType.major, -1) }
        
        let pitchClasses = notes.map { $0 % 12 }.sorted()
        let lowestNote = notes.min() ?? 0
        let lowestNotePitchClass = lowestNote % 12
        
        var bestScore = -1.0
        var bestRootPitchClass = 0
        var bestChordType = ChordType.major
        
        for rootPitchClass in 0..<12 {
            let relativePitchClasses = Set(pitchClasses.map { ($0 - rootPitchClass + 12) % 12 })
            
            for chordType in enabledChordTypes {
                let template = ChordTemplates.getTemplate(for: chordType)
                let templateSet = Set(template.map { $0 % 12 })
                
                var score = calculateF1ScoreLinear(actual: relativePitchClasses, expected: templateSet)
                
                if lowestNotePitchClass != rootPitchClass {
                    score *= 0.98
                }
                
                if score >= bestScore {
                    bestScore = score
                    bestRootPitchClass = rootPitchClass
                    bestChordType = chordType
                }
            }
        }
        
        return (bestRootPitchClass, bestChordType, lowestNotePitchClass)
    }
    
    func getChordName(bestRootPitchClass: Int, bestChordType: ChordType, lowestNotePitchClass: Int) -> String
    {
        var bestChord = "?"
        
        let rootNoteName = useFlats ?
            ChordRecognizer.flatNoteNames[bestRootPitchClass] :
            ChordRecognizer.sharpNoteNames[bestRootPitchClass]
        bestChord = getCompactChordName(rootNoteName: rootNoteName, chordType: bestChordType)

        if bestChord != "?" && lowestNotePitchClass != bestRootPitchClass {
            let bassNoteName = useFlats ?
                ChordRecognizer.flatNoteNames[lowestNotePitchClass] :
                ChordRecognizer.sharpNoteNames[lowestNotePitchClass]
            bestChord = "\(bestChord)/\(bassNoteName)"
        }
        return bestChord
    }
    
    func calculateF1ScoreLinear(actual: Set<Int>, expected: Set<Int>) -> Double {
        let sortedActual = actual.sorted()
        let sortedExpected = expected.sorted()

        var i = 0, j = 0
        var truePositives = 0
        var falsePositives = 0
        var falseNegatives = 0

        while i < sortedActual.count && j < sortedExpected.count {
            if sortedActual[i] == sortedExpected[j] {
                truePositives += 1
                i += 1
                j += 1
            } else if sortedActual[i] < sortedExpected[j] {
                falsePositives += 1
                i += 1
            } else {
                falseNegatives += 1
                j += 1
            }
        }

        // 残り要素がある場合
        falsePositives += sortedActual.count - i
        falseNegatives += sortedExpected.count - j

        let tp = Double(truePositives)
        let fp = Double(falsePositives)
        let fn = Double(falseNegatives)

        let precisionDen = tp + fp
        let recallDen = tp + fn

        let precision = (precisionDen == 0) ? 0 : tp / precisionDen
        let recall = (recallDen == 0) ? 0 : tp / recallDen

        if precision + recall == 0 {
            return 0
        }
        return (precision * recall) / (precision + recall)
    }
    
    private func getCompactChordName(rootNoteName: String, chordType: ChordType) -> String {
        switch chordType {
        case .major:
            return rootNoteName
        case .minor:
            return "\(rootNoteName)m"
        case .major7:
            return "\(rootNoteName)M7"
        case .minor7:
            return "\(rootNoteName)m7"
        case .major9:
            return "\(rootNoteName)M9"
        case .minor9:
            return "\(rootNoteName)m9"
        case .minor11:
            return "\(rootNoteName)m11"
        case .major6:
            return "\(rootNoteName)6"
        case .minor6:
            return "\(rootNoteName)m6"
        case .minoradd9:
            return "\(rootNoteName)madd9"
        case .major6add9:
            return "\(rootNoteName)69"
        case .minor6add9:
            return "\(rootNoteName)m69"
        case .add9:
            return "\(rootNoteName)add9"
        case .seventh9:
            return "\(rootNoteName)M9"
        case .seventh13:
            return "\(rootNoteName)M13"
        case .seventhSharp5:
            return "\(rootNoteName)M7#5"
        case .major7sharp11:
            return "\(rootNoteName)M7#11"
        case .dominant7:
            return "\(rootNoteName)7"
        case .dominant9:
            return "\(rootNoteName)9"
        case .dominant11:
            return "\(rootNoteName)11"
        case .dominant13:
            return "\(rootNoteName)13"
        case .dominant7sus4:
            return "\(rootNoteName)7sus4"
        case .sus2:
            return "\(rootNoteName)sus2"
        case .sus4:
            return "\(rootNoteName)sus4"
        case .augmented:
            return "\(rootNoteName)aug"
        case .augmented7:
            return "\(rootNoteName)aug7"
        case .diminished:
            return "\(rootNoteName)dim"
        case .diminished7:
            return "\(rootNoteName)dim7"
        case .minorMajor7:
            return "\(rootNoteName)mM7"
        case .minor7flat5:
            return "\(rootNoteName)m7b5"
        case .dominant7flat5:
            return "\(rootNoteName)7#11"
        case .dominant7flat9:
            return "\(rootNoteName)7b9"
        case .dominant7sharp9:
            return "\(rootNoteName)7#9"
        case .dominant7flat5flat9:
            return "\(rootNoteName)7b9#11"
        case .dominant7sharp5flat9:
            return "\(rootNoteName)7b9b13"
        case .dominant7flat5sharp9:
            return "\(rootNoteName)7#9#11"
        case .dominant7sharp5sharp9:
            return "\(rootNoteName)7#5#9"
        case .dominant7sharp9_13:
            return "\(rootNoteName)7#9,13"
        case .dominant7flat9_13:
            return "\(rootNoteName)7b9,13"
        case .dominant7flat9sharp9:
            return "\(rootNoteName)7b9#9"
        case .dominant7flat9sharp9sharp11:
            return "\(rootNoteName)7b9#9#11"
        case .dominant7flat9sharp9flat13:
            return "\(rootNoteName)7b9#9b13"
        }
    }
    
    static func getChordNotes(rootPitchClass: Int, chordType: ChordType, lowestNotePitchClass: Int) -> [Int] {
        let bassNote: Int? = nil
        
        guard rootPitchClass != -1 else { return [] }
        
        let template = ChordTemplates.getTemplate(for: chordType)
        
        let baseNote = 48 + rootPitchClass
        var result = template.map { baseNote + $0 }
        
        if (rootPitchClass != lowestNotePitchClass) {
            result.append(lowestNotePitchClass + 36)
        }
        
        if let bassNote = bassNote, !result.contains(bassNote) {
            result.append(bassNote)
        }
        
        return result
    }
}

struct ChordTemplates {
    struct Major {
        static let basic = [0, 4, 7]
        static let seventh = [0, 4, 7, 11]
        static let ninth = [0, 4, 7, 11, 14]
        static let sixth = [0, 4, 7, 9]
        static let sixthNinth = [0, 4, 7, 9, 14]
        static let add9 = [0, 4, 7, 14]
        static let seventh9 = [0, 4, 7, 11, 14]
        
        static let seventh13 = [0, 4, 9, 11]
        static let seventhSharp5 = [0, 4, 8, 11]
        
        static let seventhSharp11 = [0, 4, 6, 11]
    }
    
    struct Minor {
        static let basic = [0, 3, 7]
        static let seventh = [0, 3, 7, 10]
        static let ninth = [0, 3, 7, 10, 14]
        static let eleventh = [0, 3, 7, 10, 14, 17]
        static let sixth = [0, 3, 7, 9]
        static let sixthNinth = [0, 3, 7, 9, 14]
        static let add9 = [0, 3, 7, 14]
        static let majorSeventh = [0, 3, 7, 11]
        static let seventhFlat5 = [0, 3, 6, 10]
    }
    
    struct Dominant {
        static let seventh = [0, 4, 7, 10]
        static let ninth = [0, 4, 7, 10, 14]
        static let eleventh = [0, 4, 7, 10, 17]
        static let thirteenth = [0, 4, 7, 10, 21]
        static let seventhSus4 = [0, 5, 7, 10]
        static let seventhFlat5 = [0, 4, 6, 10]
        static let seventhFlat9 = [0, 4, 7, 10, 13]
        static let seventhSharp9 = [0, 4, 7, 10, 15]
        static let seventhFlat5Flat9 = [0, 4, 6, 10, 13]
        static let seventhSharp5Flat9 = [0, 4, 8, 10, 13]
        static let seventhFlat5Sharp9 = [0, 4, 6, 10, 15]
        static let seventhSharp5Sharp9 = [0, 4, 8, 10, 15]
        
        static let seventhSharp9_13 = [0, 4, 7, 10, 15, 20]
        static let seventhFlat9_13 = [0, 4, 7, 10, 13, 20]
        static let seventhFlat9Sharp9 = [0, 4, 7, 10, 13, 15]
        static let seventhFlat9Sharp9Sharp11 = [0, 4, 7, 10, 13, 15, 18]
        static let seventhFlat9Sharp9Flat13 = [0, 4, 7, 10, 13, 15, 20]
    }
    
    struct Suspended {
        static let sus2 = [0, 2, 7]
        static let sus4 = [0, 5, 7]
    }
    
    struct AugmentedDiminished {
        static let augmented = [0, 4, 8]
        static let augmentedSeventh = [0, 4, 8, 10]
        static let diminished = [0, 3, 6]
        static let diminishedSeventh = [0, 3, 6, 9]
    }
    
    static func getTemplate(for chordType: ChordType) -> [Int] {
        switch chordType {
        case .major: return Major.basic
        case .major7: return Major.seventh
        case .major9: return Major.ninth
        case .major6: return Major.sixth
        case .major6add9: return Major.sixthNinth
        case .add9: return Major.add9
        case .seventh9: return Major.seventh9
        case .seventh13: return Major.seventh13
        case .seventhSharp5: return Major.seventhSharp5
        case .major7sharp11: return Major.seventhSharp11
            
        case .minor: return Minor.basic
        case .minor7: return Minor.seventh
        case .minor9: return Minor.ninth
        case .minor11: return Minor.eleventh
        case .minor6: return Minor.sixth
        case .minoradd9: return Minor.add9
        case .minor6add9: return Minor.sixthNinth
        case .minorMajor7: return Minor.majorSeventh
        case .minor7flat5: return Minor.seventhFlat5
            
        case .dominant7: return Dominant.seventh
        case .dominant9: return Dominant.ninth
        case .dominant11: return Dominant.eleventh
        case .dominant13: return Dominant.thirteenth
        case .dominant7sus4: return Dominant.seventhSus4
        case .dominant7flat5: return Dominant.seventhFlat5
        case .dominant7flat9: return Dominant.seventhFlat9
        case .dominant7sharp9: return Dominant.seventhSharp9
        case .dominant7flat5flat9: return Dominant.seventhFlat5Flat9
        case .dominant7sharp5flat9: return Dominant.seventhSharp5Flat9
        case .dominant7flat5sharp9: return Dominant.seventhFlat5Sharp9
        case .dominant7sharp5sharp9: return Dominant.seventhSharp5Sharp9
        case .dominant7sharp9_13: return Dominant.seventhSharp9_13
        case .dominant7flat9_13: return Dominant.seventhFlat9_13
        case .dominant7flat9sharp9: return Dominant.seventhFlat9Sharp9
        case .dominant7flat9sharp9sharp11: return Dominant.seventhFlat9Sharp9Sharp11
        case .dominant7flat9sharp9flat13: return Dominant.seventhFlat9Sharp9Flat13
        
        case .sus2: return Suspended.sus2
        case .sus4: return Suspended.sus4
            
        case .augmented: return AugmentedDiminished.augmented
        case .augmented7: return AugmentedDiminished.augmentedSeventh
        case .diminished: return AugmentedDiminished.diminished
        case .diminished7: return AugmentedDiminished.diminishedSeventh
        }
    }
}
