# Chord Detector

A macOS menu bar application that receives MIDI signals, determines the played chord, and displays it to the user.

## Features

- Recognizes chords from MIDI input and displays the chord name in the status menu title
- Shows a dedicated floating window with the chord name in large font when clicked
- Supports drag-and-drop to save the displayed chord as a MIDI file
- Includes settings for:
  - Copying the recognized chord name to clipboard
  - Selecting enabled MIDI devices
  - Selecting enabled chord names to recognize
  - Displaying accidentals as flats or sharps
  - Quitting the application
- Supports approximately 40 commonly used chord names in pop music

## Requirements

- macOS 10.15+
- Xcode 12.0+
- Swift 5.3+

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Build and run the application

## Usage

1. Launch the application
2. The app will appear in the menu bar
3. Play chords on your MIDI device to see them recognized in the menu bar
4. Click on the menu bar item to open the floating window
5. Use the gear icon to access settings

## License

[MIT License](LICENSE)
