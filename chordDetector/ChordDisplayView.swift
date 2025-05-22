import SwiftUI

struct ChordDisplayView: View {
    @ObservedObject var chordDetectorController: ChordDetectorController
    @State private var showSettings = false
    @State private var dragChord: String?
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showSettings) {
                    SettingsView(chordDetectorController: chordDetectorController)
                }
            }
            .padding([.top, .trailing], 10)
            
            Spacer()
            
            Text(chordDetectorController.currentChord)
                .font(.system(size: 24, weight: .bold))
                .padding()
                .onDrag {
                    self.dragChord = chordDetectorController.currentChord
                    if let url = chordDetectorController.createMIDIFile(for: chordDetectorController.currentChord) {
                        let provider = NSItemProvider(contentsOf: url)
                        return provider ?? NSItemProvider()
                    }
                    return NSItemProvider()
                }
            
            Spacer()
        }
        .frame(width: 300, height: 200)
    }
}

struct SettingsView: View {
    @ObservedObject var chordDetectorController: ChordDetectorController
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                Text("MIDI Devices").tag(0)
                Text("Chord Types").tag(1)
                Text("Display").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedTab == 0 {
                midiDevicesView
            } else if selectedTab == 1 {
                chordTypesView
            } else {
                displaySettingsView
            }
            
            Divider()
            
            Button(action: {
                chordDetectorController.copyChordNameToClipboard()
            }) {
                Label("Copy Chord Name", systemImage: "doc.on.doc")
            }
            .padding(.vertical, 5)
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit", systemImage: "power")
            }
            .padding(.vertical, 5)
        }
        .frame(width: 300, height: 400)
        .padding()
    }
    
    var midiDevicesView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(chordDetectorController.availableMIDIDevices) { device in
                    Toggle(device.name, isOn: Binding(
                        get: { chordDetectorController.selectedMIDIDevices.contains(device) },
                        set: { _ in chordDetectorController.toggleMIDIDevice(device) }
                    ))
                    .padding(.vertical, 2)
                }
                
                if chordDetectorController.availableMIDIDevices.isEmpty {
                    Text("No MIDI devices found")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    var chordTypesView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(ChordType.allCases, id: \.self) { chordType in
                    Toggle(chordType.rawValue, isOn: Binding(
                        get: { chordDetectorController.enabledChordTypes.contains(chordType) },
                        set: { _ in chordDetectorController.toggleChordType(chordType) }
                    ))
                    .padding(.vertical, 2)
                }
            }
            .padding()
        }
    }
    
    var displaySettingsView: some View {
        VStack(alignment: .leading) {
            Toggle("Display accidentals as flats", isOn: Binding(
                get: { chordDetectorController.useFlats },
                set: { _ in chordDetectorController.toggleAccidentalDisplay() }
            ))
            .padding()
            
            Spacer()
        }
        .padding()
    }
}
