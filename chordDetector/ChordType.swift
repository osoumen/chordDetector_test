import Foundation

enum ChordType: String, CaseIterable {
    case major = "Major"
    case major7 = "Major 7"
    case major9 = "Major 9"
    case major6 = "Major 6"
    case major6add9 = "Major 6/9"
    case add9 = "Add 9"
    case add11 = "Add 11"
    case major7sharp11 = "Major 7#11"
    case add2 = "Add 2"
    case add4 = "Add 4"
    
    case minor = "Minor"
    case minor7 = "Minor 7"
    case minor9 = "Minor 9"
    case minor11 = "Minor 11"
    case minor6 = "Minor 6"
    case minor6add9 = "Minor 6/9"
    case minorMajor7 = "Minor/Major 7"
    case minor7flat5 = "Minor 7b5"
    
    case dominant7 = "Dominant 7"
    case dominant9 = "Dominant 9"
    case dominant11 = "Dominant 11"
    case dominant13 = "Dominant 13"
    case dominant7sus4 = "Dominant 7sus4"
    case dominant7flat5 = "Dominant 7b5"
    case dominant7sharp5 = "Dominant 7#5"
    case dominant7flat9 = "Dominant 7b9"
    case dominant7sharp9 = "Dominant 7#9"
    case dominant7flat5flat9 = "Dominant 7b5b9"
    case dominant7sharp5flat9 = "Dominant 7#5b9"
    case dominant7flat5sharp9 = "Dominant 7b5#9"
    case dominant7sharp5sharp9 = "Dominant 7#5#9"
    
    case sus2 = "Sus 2"
    case sus4 = "Sus 4"
    
    case augmented = "Augmented"
    case augmented7 = "Augmented 7"
    case diminished = "Diminished"
    case diminished7 = "Diminished 7"
    case halfDiminished7 = "Half-Diminished 7"
    
    case power = "Power"
}
