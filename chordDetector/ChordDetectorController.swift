import Foundation
import CoreMIDI
import AppKit

class ChordDetectorController: ObservableObject {
    @Published var currentChord: String = "---"
    @Published var activeNotes: Set<Int> = []
    @Published var availableMIDIDevices: [MIDIDevice] = []
    @Published var selectedMIDIDevices: [MIDIDevice] = []
    @Published var enabledChordTypes: [ChordType] = ChordType.allCases
    @Published var useFlats: Bool = false
    
    private var midiClient: MIDIClientRef = 0
    private var midiInputPort: MIDIPortRef = 0
    private var midiSources: [MIDIEndpointRef] = []
    private var chordUpdateCallback: ((String) -> Void)?
    private var isDamperActive: Bool = false
    private var heldNotes: Set<Int> = []
    
    init() {
        setupMIDI()
        loadSettings()
    }
    
    func enableTitleUpdate(chordUpdateCallback: @escaping (String) -> Void) {
        self.chordUpdateCallback = chordUpdateCallback
    }
    
    func startMIDIMonitoring() {
        connectToMIDIDevices()
    }
    
    func stopMIDIMonitoring() {
        disconnectFromMIDIDevices()
    }
    
    func createMIDIFile(for chordName: String) -> URL? {
        let chordNotes = ChordRecognizer.getChordNotes(for: chordName)
        if chordNotes.isEmpty {
            return nil
        }
        
        let midiFileCreator = MIDIFileCreator()
        return midiFileCreator.createMIDIFile(for: chordNotes, named: chordName)
    }
    
    func copyChordNameToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(currentChord, forType: .string)
    }
    
    func toggleAccidentalDisplay() {
        useFlats.toggle()
        saveSettings()
        updateChordDisplay()
    }
    
    func toggleChordType(_ chordType: ChordType) {
        if enabledChordTypes.contains(chordType) {
            enabledChordTypes.removeAll { $0 == chordType }
        } else {
            enabledChordTypes.append(chordType)
        }
        saveSettings()
        updateChordDisplay()
    }
    
    func toggleMIDIDevice(_ device: MIDIDevice) {
        if selectedMIDIDevices.contains(device) {
            selectedMIDIDevices.removeAll { $0 == device }
        } else {
            selectedMIDIDevices.append(device)
        }
        saveSettings()
        connectToMIDIDevices()
    }
    
    
    private func setupMIDI() {
        let status = MIDIClientCreateWithBlock("ChordDetector" as CFString, &midiClient) { [weak self] notificationPointer in
            self?.handleMIDINotification(notificationPointer.pointee)
        }
        
        if status != noErr {
            print("Error creating MIDI client: \(status)")
            return
        }
        
        let inputPortStatus = MIDIInputPortCreateWithBlock(midiClient, "ChordDetectorInput" as CFString, &midiInputPort) { [weak self] packetList, _ in
            self?.processMIDIPacketList(packetList.pointee)
        }
        
        if inputPortStatus != noErr {
            print("Error creating MIDI input port: \(inputPortStatus)")
            return
        }
        
        refreshAvailableMIDIDevices()
    }
    
    private func refreshAvailableMIDIDevices() {
        availableMIDIDevices.removeAll()
        
        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let source = MIDIGetSource(i)
            var name: Unmanaged<CFString>?
            var manufacturer: Unmanaged<CFString>?
            var model: Unmanaged<CFString>?
            
            MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name)
            MIDIObjectGetStringProperty(source, kMIDIPropertyManufacturer, &manufacturer)
            MIDIObjectGetStringProperty(source, kMIDIPropertyModel, &model)
            
            if let cfName = name?.takeRetainedValue() {
                let deviceName = cfName as String
                let manufacturerName = manufacturer?.takeRetainedValue() as String? ?? ""
                let modelName = model?.takeRetainedValue() as String? ?? ""
                
                var components: [String] = []

                if !modelName.isEmpty &&
                   !deviceName.lowercased().contains(modelName.lowercased()) && 
                   !manufacturerName.lowercased().contains(modelName.lowercased()) {
                    components.append(modelName)
                }
                
                components.append(deviceName)

                let fullName = components.joined(separator: " ")
                let device = MIDIDevice(id: Int(source), name: fullName)
                availableMIDIDevices.append(device)
            }
        }
    }
    
    private func connectToMIDIDevices() {
        disconnectFromMIDIDevices()
        
        for device in selectedMIDIDevices {
            let source = MIDIEndpointRef(device.id)
            let connectStatus = MIDIPortConnectSource(midiInputPort, source, nil)
            if connectStatus == noErr {
                midiSources.append(source)
            } else {
                print("Error connecting to MIDI source \(device.name): \(connectStatus)")
            }
        }
    }
    
    private func disconnectFromMIDIDevices() {
        for source in midiSources {
            MIDIPortDisconnectSource(midiInputPort, source)
        }
        midiSources.removeAll()
    }
    
    private func handleMIDINotification(_ notification: MIDINotification) {
        switch notification.messageID {
        case .msgSetupChanged:
            refreshAvailableMIDIDevices()
        default:
            break
        }
    }
    
    private func processMIDIPacketList(_ packetList: MIDIPacketList) {
        let packets = packetList.packet
        var packet = packets
        
        for _ in 0..<packetList.numPackets {
            let packetData = withUnsafePointer(to: packet.data) { ptr in
                Data(bytes: ptr, count: Int(packet.length))
            }
            
            processMIDIPacket(packetData)
            
            packet = MIDIPacketNext(&packet).pointee
        }
    }
    
    private func processMIDIPacket(_ packetData: Data) {
        guard packetData.count >= 3 else { return }
        
        let status = packetData[0]
        let statusType = status & 0xF0
        
        if statusType == 0x90 || statusType == 0x80 {
            let note = Int(packetData[1])
            let velocity = Int(packetData[2])
            
            if statusType == 0x90 && velocity > 0 {
                activeNotes.insert(note)
                updateChordDisplay()
            } else {
                if !isDamperActive {
                    activeNotes.remove(note)
//                    updateChordDisplay()
                } else {
                    heldNotes.insert(note)
                }
            }
        } else if statusType == 0xB0 { // Control Change
            let controlNumber = packetData[1]
            let controlValue = packetData[2]
            
            if controlNumber == 64 {
                let isDamperOn = controlValue >= 64
                isDamperActive = isDamperOn
                
                if !isDamperOn {
                    let hadHeldNotes = !heldNotes.isEmpty
                    for note in heldNotes {
                        activeNotes.remove(note)
                    }
                    heldNotes.removeAll()
                    if hadHeldNotes {
                        updateChordDisplay()
                    }
                }
            }
        }
    }
    
    private var inactivityTimer: Timer?
    
    private func updateChordDisplay() {
        inactivityTimer?.invalidate()
        
        if activeNotes.isEmpty {
            currentChord = "---"
        } else {
            let recognizer = ChordRecognizer(enabledChordTypes: enabledChordTypes, useFlats: useFlats)
            currentChord = recognizer.recognizeChord(from: activeNotes)
            
            inactivityTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if !self.activeNotes.isEmpty && self.currentChord != "---" {
                    self.activeNotes.removeAll()
                    self.currentChord = "---"
                    self.chordUpdateCallback?(self.currentChord)
                }
            }
        }
        
        chordUpdateCallback?(currentChord)
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        if let savedDeviceData = defaults.data(forKey: "selectedMIDIDevices"),
           let devices = try? JSONDecoder().decode([MIDIDevice].self, from: savedDeviceData) {
            selectedMIDIDevices = devices
        }
        
        if let savedChordTypesData = defaults.data(forKey: "enabledChordTypes"),
           let chordTypes = try? JSONDecoder().decode([ChordType].self, from: savedChordTypesData) {
            enabledChordTypes = chordTypes
        } else {
            enabledChordTypes = ChordType.allCases
        }
        
        useFlats = defaults.bool(forKey: "useFlats")
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        
        if let encodedDevices = try? JSONEncoder().encode(selectedMIDIDevices) {
            defaults.set(encodedDevices, forKey: "selectedMIDIDevices")
        }
        
        if let encodedChordTypes = try? JSONEncoder().encode(enabledChordTypes) {
            defaults.set(encodedChordTypes, forKey: "enabledChordTypes")
        }
        
        defaults.set(useFlats, forKey: "useFlats")
    }
}


struct MIDIDevice: Identifiable, Equatable, Codable {
    let id: Int
    let name: String
}

enum ChordType: String, CaseIterable, Codable {
    case major = "Major"
    case major7 = "Major 7"
    case major9 = "Major 9"
    case major6 = "Major 6"
    case major6add9 = "Major 6/9"
    case add9 = "Add 9"
    case add11 = "Add 11"
    
    case minor = "Minor"
    case minor7 = "Minor 7"
    case minor9 = "Minor 9"
    case minor11 = "Minor 11"
    case minor6 = "Minor 6"
    case minor6add9 = "Minor 6/9"
    case minorMajor7 = "Minor Major 7"
    
    case dominant7 = "Dominant 7"
    case dominant9 = "Dominant 9"
    case dominant11 = "Dominant 11"
    case dominant13 = "Dominant 13"
    case dominant7sus4 = "Dominant 7 sus4"
    
    case sus2 = "Sus 2"
    case sus4 = "Sus 4"
    
    case augmented = "Augmented"
    case augmented7 = "Augmented 7"
    case diminished = "Diminished"
    case diminished7 = "Diminished 7"
    case halfDiminished7 = "Half-Diminished 7"
    
    case dominant7flat5 = "Dominant 7 ♭5"
    case dominant7sharp5 = "Dominant 7 ♯5"
    case dominant7flat9 = "Dominant 7 ♭9"
    case dominant7sharp9 = "Dominant 7 ♯9"
    case dominant7flat5flat9 = "Dominant 7 ♭5 ♭9"
    case dominant7sharp5flat9 = "Dominant 7 ♯5 ♭9"
    case dominant7flat5sharp9 = "Dominant 7 ♭5 ♯9"
    case dominant7sharp5sharp9 = "Dominant 7 ♯5 ♯9"
    
    case power = "Power (5)"
    
    case add2 = "Add 2"
    case add4 = "Add 4"
    case major7sharp11 = "Major 7 ♯11"
    case minor7flat5 = "Minor 7 ♭5"
}
