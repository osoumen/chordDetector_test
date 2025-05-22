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
        let lowestNote = notes.min() ?? 0
        let lowestNotePitchClass = lowestNote % 12
        
        var bestChord = "?"
        var bestScore = -1.0
        var bestRootPitchClass = 0
        
        for rootPitchClass in 0..<12 {
            let relativePitchClasses = Set(pitchClasses.map { ($0 - rootPitchClass + 12) % 12 })
            
            for chordType in enabledChordTypes {
                let template = ChordTemplates.getTemplate(for: chordType)
                let templateSet = Set(template.map { $0 % 12 })
                
                let score = calculateF1Score(actual: relativePitchClasses, expected: templateSet)
                
                if score > bestScore {
                    bestScore = score
                    bestRootPitchClass = rootPitchClass
                    let rootNoteName = useFlats ? 
                        ChordRecognizer.flatNoteNames[rootPitchClass] : 
                        ChordRecognizer.sharpNoteNames[rootPitchClass]
                    bestChord = getCompactChordName(rootNoteName: rootNoteName, chordType: chordType)
                }
            }
        }
        
        if bestChord != "?" && lowestNotePitchClass != bestRootPitchClass {
            let bassNoteName = useFlats ? 
                ChordRecognizer.flatNoteNames[lowestNotePitchClass] : 
                ChordRecognizer.sharpNoteNames[lowestNotePitchClass]
            bestChord = "\(bestChord)/\(bassNoteName)"
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
    
    private func getCompactChordName(rootNoteName: String, chordType: ChordType) -> String {
        switch chordType {
        case .major:
            return rootNoteName
        case .minor:
            return "\(rootNoteName)m"
        case .major7:
            return "\(rootNoteName)maj7"
        case .minor7:
            return "\(rootNoteName)m7"
        case .major9:
            return "\(rootNoteName)maj9"
        case .minor9:
            return "\(rootNoteName)m9"
        case .minor11:
            return "\(rootNoteName)m11"
        case .major6:
            return "\(rootNoteName)6"
        case .minor6:
            return "\(rootNoteName)m6"
        case .major6add9:
            return "\(rootNoteName)6/9"
        case .minor6add9:
            return "\(rootNoteName)m6/9"
        case .add9:
            return "\(rootNoteName)add9"
        case .add11:
            return "\(rootNoteName)add11"
        case .add2:
            return "\(rootNoteName)add2"
        case .add4:
            return "\(rootNoteName)add4"
        case .major7sharp11:
            return "\(rootNoteName)maj7#11"
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
        case .halfDiminished7:
            return "\(rootNoteName)m7b5"
        case .minorMajor7:
            return "\(rootNoteName)mM7"
        case .minor7flat5:
            return "\(rootNoteName)m7b5"
        case .dominant7flat5:
            return "\(rootNoteName)7b5"
        case .dominant7sharp5:
            return "\(rootNoteName)7#5"
        case .dominant7flat9:
            return "\(rootNoteName)7b9"
        case .dominant7sharp9:
            return "\(rootNoteName)7#9"
        case .dominant7flat5flat9:
            return "\(rootNoteName)7b5b9"
        case .dominant7sharp5flat9:
            return "\(rootNoteName)7#5b9"
        case .dominant7flat5sharp9:
            return "\(rootNoteName)7b5#9"
        case .dominant7sharp5sharp9:
            return "\(rootNoteName)7#5#9"
        case .power:
            return "\(rootNoteName)5"
        }
    }
    
    static func getChordNotes(for chordName: String) -> [Int] {
        let components: [String]
        var bassNote: Int? = nil
        
        if chordName.contains("/") {
            let slashComponents = chordName.split(separator: "/", maxSplits: 1).map(String.init)
            components = [slashComponents[0]]
            
            if slashComponents.count > 1 {
                let bassNoteName = slashComponents[1].trimmingCharacters(in: .whitespaces)
                for i in 0..<12 {
                    if sharpNoteNames[i] == bassNoteName || flatNoteNames[i] == bassNoteName {
                        bassNote = 48 + i // Use a lower octave for bass note
                        break
                    }
                }
            }
        } else {
            components = chordName.split(separator: " ", maxSplits: 1).map(String.init)
        }
        
        guard !components.isEmpty else { return [] }
        
        var rootNoteName = components[0]
        var chordTypeName = ""
        
        if components.count == 1 {
            if rootNoteName.count > 1 {
                if rootNoteName.hasSuffix("7sus4") {
                    chordTypeName = "Dominant 7 sus4" // Ensure this matches exactly with ChordType.dominant7sus4.rawValue
                    rootNoteName = String(rootNoteName.dropLast(5))
                } else if rootNoteName.hasSuffix("m7b5") {
                    chordTypeName = "Minor 7 ♭5" // Ensure this matches exactly with ChordType.minor7flat5.rawValue
                    rootNoteName = String(rootNoteName.dropLast(4))
                } else {
                    let secondChar = rootNoteName[rootNoteName.index(rootNoteName.startIndex, offsetBy: 1)]
                    if secondChar == "m" || secondChar == "M" || secondChar == "7" || secondChar == "9" || 
                       secondChar == "6" || secondChar == "5" || secondChar == "4" || secondChar == "2" ||
                       secondChar == "a" || secondChar == "d" || secondChar == "s" {
                        if rootNoteName == "\(rootNoteName.prefix(1))m" {
                            chordTypeName = "Minor"
                        } else if rootNoteName == "\(rootNoteName.prefix(1))m7" {
                            chordTypeName = "Minor 7"
                        } else if rootNoteName == "\(rootNoteName.prefix(1))maj7" {
                            chordTypeName = "Major 7"
                        } else if rootNoteName == "\(rootNoteName.prefix(1))7" {
                            chordTypeName = "Dominant 7"
                        } else if rootNoteName == "\(rootNoteName.prefix(1))dim" {
                            chordTypeName = "Diminished"
                        } else if rootNoteName == "\(rootNoteName.prefix(1))aug" {
                            chordTypeName = "Augmented"
                        } else if rootNoteName == "\(rootNoteName.prefix(1))sus4" {
                            chordTypeName = "Sus 4"
                        } else {
                            chordTypeName = "Major"
                        }
                        rootNoteName = String(rootNoteName.prefix(1))
                    } else {
                        chordTypeName = "Major"
                    }
                }
            } else {
                chordTypeName = "Major"
            }
        } else if components.count == 2 {
            chordTypeName = components[1]
        }
        
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
        var result = template.map { baseNote + $0 }
        
        if let bassNote = bassNote, !result.contains(bassNote) {
            result.insert(bassNote, at: 0)
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
        static let seventhFlat5 = [0, 3, 6, 10] // Correct voicing for Dm7b5: D, F, Ab, C
    }
    
    struct Dominant {
        static let seventh = [0, 4, 7, 10]
        static let ninth = [0, 4, 7, 10, 14]
        static let eleventh = [0, 4, 7, 10, 14, 17]
        static let thirteenth = [0, 4, 7, 10, 14, 17, 21]
        static let seventhSus4 = [0, 5, 7, 10] // Correct voicing for C7sus4: C, F, G, Bb
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
