import XCTest
@testable import chordDetector

class ChordRecognizerTests: XCTestCase {
    
    func testMajorChordRecognition() {
        let recognizer = ChordRecognizer(enabledChordTypes: ChordType.allCases, useFlats: false)
        
        let cMajorNotes: Set<Int> = [60, 64, 67]
        XCTAssertEqual(recognizer.recognizeChord(from: cMajorNotes), "C Major")
        
        let fMajorNotes: Set<Int> = [65, 69, 72]
        XCTAssertEqual(recognizer.recognizeChord(from: fMajorNotes), "F Major")
        
        let gMajorNotes: Set<Int> = [67, 71, 74]
        XCTAssertEqual(recognizer.recognizeChord(from: gMajorNotes), "G Major")
    }
    
    func testMinorChordRecognition() {
        let recognizer = ChordRecognizer(enabledChordTypes: ChordType.allCases, useFlats: false)
        
        let aMinorNotes: Set<Int> = [69, 72, 76]
        XCTAssertEqual(recognizer.recognizeChord(from: aMinorNotes), "A Minor")
        
        let eMinorNotes: Set<Int> = [64, 67, 71]
        XCTAssertEqual(recognizer.recognizeChord(from: eMinorNotes), "E Minor")
        
        let dMinorNotes: Set<Int> = [62, 65, 69]
        XCTAssertEqual(recognizer.recognizeChord(from: dMinorNotes), "D Minor")
    }
    
    func testDominant7ChordRecognition() {
        let recognizer = ChordRecognizer(enabledChordTypes: ChordType.allCases, useFlats: false)
        
        let g7Notes: Set<Int> = [67, 71, 74, 77]
        XCTAssertEqual(recognizer.recognizeChord(from: g7Notes), "G Dominant 7")
        
        let c7Notes: Set<Int> = [60, 64, 67, 70]
        XCTAssertEqual(recognizer.recognizeChord(from: c7Notes), "C Dominant 7")
    }
    
    func testSuspendedChordRecognition() {
        let recognizer = ChordRecognizer(enabledChordTypes: ChordType.allCases, useFlats: false)
        
        let dsus4Notes: Set<Int> = [62, 67, 69]
        XCTAssertEqual(recognizer.recognizeChord(from: dsus4Notes), "D Sus 4")
        
        let asus2Notes: Set<Int> = [69, 71, 76]
        XCTAssertEqual(recognizer.recognizeChord(from: asus2Notes), "A Sus 2")
    }
    
    func testChordRecognitionWithDifferentOctaves() {
        let recognizer = ChordRecognizer(enabledChordTypes: ChordType.allCases, useFlats: false)
        
        let cMajorDifferentOctaves: Set<Int> = [48, 64, 79] // C3, E4, G5
        XCTAssertEqual(recognizer.recognizeChord(from: cMajorDifferentOctaves), "C Major")
    }
    
    func testAccidentalDisplayPreference() {
        let sharpRecognizer = ChordRecognizer(enabledChordTypes: ChordType.allCases, useFlats: false)
        let fSharpMajorNotes: Set<Int> = [66, 70, 73] // F#, A#, C#
        XCTAssertEqual(sharpRecognizer.recognizeChord(from: fSharpMajorNotes), "F♯ Major")
        
        let flatRecognizer = ChordRecognizer(enabledChordTypes: ChordType.allCases, useFlats: true)
        XCTAssertEqual(flatRecognizer.recognizeChord(from: fSharpMajorNotes), "G♭ Major")
    }
    
    func testEmptyInput() {
        let recognizer = ChordRecognizer(enabledChordTypes: ChordType.allCases, useFlats: false)
        XCTAssertEqual(recognizer.recognizeChord(from: []), "---")
    }
    
    func testChordTemplateGeneration() {
        let cMajorNotes = ChordRecognizer.getChordNotes(for: "C Major")
        XCTAssertEqual(cMajorNotes, [60, 64, 67]) // C4, E4, G4
        
        let gMinor7Notes = ChordRecognizer.getChordNotes(for: "G Minor 7")
        XCTAssertEqual(gMinor7Notes, [67, 70, 74, 77]) // G4, Bb4, D5, F5
    }
}
