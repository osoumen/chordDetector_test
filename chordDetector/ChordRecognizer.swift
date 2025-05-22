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
    
    func recognizeChord(from notes: Set<Int>) -> String {
        guard !notes.isEmpty else { return "---" }
        guard !enabledChordTypes.isEmpty else { return "" }
        
        let pitchClasses = notes.map { $0 % 12 }.sorted()
        
        var bestChord = "?"
        var bestScore = -1.0
        
        for rootPitchClass in 0..<12 {
            let relativePitchClasses = Set(pitchClasses.map { ($0 - rootPitchClass + 12) % 12 })
            
            for chordType in enabledChordTypes {
                let template = ChordTemplates.getTemplate(for: chordType)
                let templateSet = Set(template.map { $0 % 12 })
                
                let score = calculateF1Score(actual: relativePitchClasses, expected: templateSet)
                
                if score > bestScore {
                    bestScore = score
                    let rootNoteName = useFlats ? 
                        ChordRecognizer.flatNoteNames[rootPitchClass] : 
                        ChordRecognizer.sharpNoteNames[rootPitchClass]
                    bestChord = "\(rootNoteName) \(chordType.rawValue)"
                }
            }
        }
        
        return bestChord
    }
    
    private func calculateF1Score(actual: Set<Int>, expected: Set<Int>) -> Double {
        let truePositives = Double(actual.intersection(expected).count)
        let falsePositives = Double(actual.subtracting(expected).count)
        let falseNegatives = Double(expected.subtracting(actual).count)
        
        let precision = truePositives / (truePositives + falsePositives)
        let recall = truePositives / (truePositives + falseNegatives)
        
        if precision + recall == 0 {
            return 0
        }
        return 2 * precision * recall / (precision + recall)
    }
    
    static func getChordNotes(for chordName: String) -> [Int] {
        let components = chordName.split(separator: " ", maxSplits: 1)
        guard components.count == 2 else { return [] }
        
        let rootNoteName = String(components[0])
        let chordTypeName = String(components[1])
        
        var rootPitchClass = -1
        for i in 0..<12 {
            if sharpNoteNames[i] == rootNoteName || flatNoteNames[i] == rootNoteName {
                rootPitchClass = i
                break
            }
        }
        
        guard rootPitchClass != -1 else { return [] }
        
        guard let chordType = ChordType(rawValue: chordTypeName) else { return [] }
        
        let template = ChordTemplates.getTemplate(for: chordType)
        
        let baseNote = 60 + rootPitchClass
        return template.map { baseNote + $0 }
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
        static let add11 = [0, 4, 7, 17]
        static let seventhSharp11 = [0, 4, 7, 11, 18]
        static let add2 = [0, 2, 4, 7]
        static let add4 = [0, 4, 5, 7]
    }
    
    struct Minor {
        static let basic = [0, 3, 7]
        static let seventh = [0, 3, 7, 10]
        static let ninth = [0, 3, 7, 10, 14]
        static let eleventh = [0, 3, 7, 10, 14, 17]
        static let sixth = [0, 3, 7, 9]
        static let sixthNinth = [0, 3, 7, 9, 14]
        static let majorSeventh = [0, 3, 7, 11]
        static let seventhFlat5 = [0, 3, 6, 10]
    }
    
    struct Dominant {
        static let seventh = [0, 4, 7, 10]
        static let ninth = [0, 4, 7, 10, 14]
        static let eleventh = [0, 4, 7, 10, 14, 17]
        static let thirteenth = [0, 4, 7, 10, 14, 17, 21]
        static let seventhSus4 = [0, 5, 7, 10]
        static let seventhFlat5 = [0, 4, 6, 10]
        static let seventhSharp5 = [0, 4, 8, 10]
        static let seventhFlat9 = [0, 4, 7, 10, 13]
        static let seventhSharp9 = [0, 4, 7, 10, 15]
        static let seventhFlat5Flat9 = [0, 4, 6, 10, 13]
        static let seventhSharp5Flat9 = [0, 4, 8, 10, 13]
        static let seventhFlat5Sharp9 = [0, 4, 6, 10, 15]
        static let seventhSharp5Sharp9 = [0, 4, 8, 10, 15]
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
        static let halfDiminishedSeventh = [0, 3, 6, 10]
    }
    
    struct Power {
        static let basic = [0, 7]
    }
    
    static func getTemplate(for chordType: ChordType) -> [Int] {
        switch chordType {
        case .major: return Major.basic
        case .major7: return Major.seventh
        case .major9: return Major.ninth
        case .major6: return Major.sixth
        case .major6add9: return Major.sixthNinth
        case .add9: return Major.add9
        case .add11: return Major.add11
        case .major7sharp11: return Major.seventhSharp11
        case .add2: return Major.add2
        case .add4: return Major.add4
            
        case .minor: return Minor.basic
        case .minor7: return Minor.seventh
        case .minor9: return Minor.ninth
        case .minor11: return Minor.eleventh
        case .minor6: return Minor.sixth
        case .minor6add9: return Minor.sixthNinth
        case .minorMajor7: return Minor.majorSeventh
        case .minor7flat5: return Minor.seventhFlat5
            
        case .dominant7: return Dominant.seventh
        case .dominant9: return Dominant.ninth
        case .dominant11: return Dominant.eleventh
        case .dominant13: return Dominant.thirteenth
        case .dominant7sus4: return Dominant.seventhSus4
        case .dominant7flat5: return Dominant.seventhFlat5
        case .dominant7sharp5: return Dominant.seventhSharp5
        case .dominant7flat9: return Dominant.seventhFlat9
        case .dominant7sharp9: return Dominant.seventhSharp9
        case .dominant7flat5flat9: return Dominant.seventhFlat5Flat9
        case .dominant7sharp5flat9: return Dominant.seventhSharp5Flat9
        case .dominant7flat5sharp9: return Dominant.seventhFlat5Sharp9
        case .dominant7sharp5sharp9: return Dominant.seventhSharp5Sharp9
            
        case .sus2: return Suspended.sus2
        case .sus4: return Suspended.sus4
            
        case .augmented: return AugmentedDiminished.augmented
        case .augmented7: return AugmentedDiminished.augmentedSeventh
        case .diminished: return AugmentedDiminished.diminished
        case .diminished7: return AugmentedDiminished.diminishedSeventh
        case .halfDiminished7: return AugmentedDiminished.halfDiminishedSeventh
            
        case .power: return Power.basic
        }
    }
}
