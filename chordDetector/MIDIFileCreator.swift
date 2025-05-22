import Foundation
import CoreMIDI

class MIDIFileCreator {
    private let headerChunk = "MThd"
    private let trackChunk = "MTrk"
    private let endOfTrack: [UInt8] = [0x00, 0xFF, 0x2F, 0x00]
    
    func createMIDIFile(for notes: [Int], named chordName: String) -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        
        var fileName = chordName
        fileName = fileName.replacingOccurrences(of: " ", with: "_")
        fileName = fileName.replacingOccurrences(of: "♯", with: "sharp")
        fileName = fileName.replacingOccurrences(of: "#", with: "sharp")
        fileName = fileName.replacingOccurrences(of: "♭", with: "flat")
        fileName = fileName.replacingOccurrences(of: "b", with: "flat")
        fileName = fileName.replacingOccurrences(of: "/", with: "_over_")
        
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-."))
        fileName = fileName.components(separatedBy: allowedCharacters.inverted).joined()
        
        let fileURL = tempDir.appendingPathComponent("\(fileName).mid")
        
        let midiData = createMIDIData(for: notes, named: sanitizeMetaEventString(chordName))
        
        do {
            try midiData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error writing MIDI file: \(error)")
            return nil
        }
    }
    
    private func sanitizeMetaEventString(_ input: String) -> String {
        return input.replacingOccurrences(of: "♯", with: "#")
               .replacingOccurrences(of: "♭", with: "b")
    }
    
    private func createMIDIData(for notes: [Int], named chordName: String) -> Data {
        var data = Data()
        
        data.append(headerChunk.data(using: .ascii)!)
        
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x06])
        
        data.append(contentsOf: [0x00, 0x00])
        
        data.append(contentsOf: [0x00, 0x01])
        
        data.append(contentsOf: [0x01, 0xE0])
        
        data.append(trackChunk.data(using: .ascii)!)
        
        let trackLengthPosition = data.count
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        let trackStartPosition = data.count
        
        let trackNameData = chordName.data(using: .ascii)!
        let trackNameLength = UInt8(trackNameData.count)
        data.append(contentsOf: [0x00, 0xFF, 0x03, trackNameLength])
        data.append(trackNameData)
        
        data.append(contentsOf: [0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20])
        
        data.append(contentsOf: [0x00, 0xFF, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08])
        
        for note in notes {
            data.append(contentsOf: [0x00, 0x90, UInt8(note), 0x64]) // Channel 1, velocity 100
        }
        
        // Use a consistent whole note duration for all notes (4 beats at 480 ticks per quarter note = 1920 ticks)
        for note in notes {
            data.append(contentsOf: [0x8F, 0x7F, 0x80, UInt8(note), 0x00]) // Whole note duration (4 beats)
        }
        
        data.append(contentsOf: endOfTrack)
        
        let trackLength = data.count - trackStartPosition
        let trackLengthBytes: [UInt8] = [
            UInt8((trackLength >> 24) & 0xFF),
            UInt8((trackLength >> 16) & 0xFF),
            UInt8((trackLength >> 8) & 0xFF),
            UInt8(trackLength & 0xFF)
        ]
        
        for i in 0..<4 {
            data[trackLengthPosition + i] = trackLengthBytes[i]
        }
        
        return data
    }
}
