#!/bin/python3

# https://github.com/robsoncouto/arduino-songs

# Converts an Arduino Song ino or MIDI file into a binary file for the Music programs

import argparse
import re
import pretty_midi

NOTES = {
    'NOTE_B0': 31,
    'NOTE_C1': 33,
    'NOTE_CS1': 35,
    'NOTE_D1': 37,
    'NOTE_DS1': 39,
    'NOTE_E1': 41,
    'NOTE_F1': 44,
    'NOTE_FS1': 46,
    'NOTE_G1': 49,
    'NOTE_GS1': 52,
    'NOTE_A1': 55,
    'NOTE_AS1': 58,
    'NOTE_B1': 62,
    'NOTE_C2': 65,
    'NOTE_CS2': 69,
    'NOTE_D2': 73,
    'NOTE_DS2': 78,
    'NOTE_E2': 82,
    'NOTE_F2': 87,
    'NOTE_FS2': 93,
    'NOTE_G2': 98,
    'NOTE_GS2': 104,
    'NOTE_A2': 110,
    'NOTE_AS2': 117,
    'NOTE_B2': 123,
    'NOTE_C3': 131,
    'NOTE_CS3': 139,
    'NOTE_D3': 147,
    'NOTE_DS3': 156,
    'NOTE_E3': 165,
    'NOTE_F3': 175,
    'NOTE_FS3': 185,
    'NOTE_G3': 196,
    'NOTE_GS3': 208,
    'NOTE_A3': 220,
    'NOTE_AS3': 233,
    'NOTE_B3': 247,
    'NOTE_C4': 262,
    'NOTE_CS4': 277,
    'NOTE_D4': 294,
    'NOTE_DS4': 311,
    'NOTE_E4': 330,
    'NOTE_F4': 349,
    'NOTE_FS4': 370,
    'NOTE_G4': 392,
    'NOTE_GS4': 415,
    'NOTE_A4': 440,
    'NOTE_AS4': 466,
    'NOTE_B4': 494,
    'NOTE_C5': 523,
    'NOTE_CS5': 554,
    'NOTE_D5': 587,
    'NOTE_DS5': 622,
    'NOTE_E5': 659,
    'NOTE_F5': 698,
    'NOTE_FS5': 740,
    'NOTE_G5': 784,
    'NOTE_GS5': 831,
    'NOTE_A5': 880,
    'NOTE_AS5': 932,
    'NOTE_B5': 988,
    'NOTE_C6': 1047,
    'NOTE_CS6': 1109,
    'NOTE_D6': 1175,
    'NOTE_DS6': 1245,
    'NOTE_E6': 1319,
    'NOTE_F6': 1397,
    'NOTE_FS6': 1480,
    'NOTE_G6': 1568,
    'NOTE_GS6': 1661,
    'NOTE_A6': 1760,
    'NOTE_AS6': 1865,
    'NOTE_B6': 1976,
    'NOTE_C7': 2093,
    'NOTE_CS7': 2217,
    'NOTE_D7': 2349,
    'NOTE_DS7': 2489,
    'NOTE_E7': 2637,
    'NOTE_F7': 2794,
    'NOTE_FS7': 2960,
    'NOTE_G7': 3136,
    'NOTE_GS7': 3322,
    'NOTE_A7': 3520,
    'NOTE_AS7': 3729,
    'NOTE_B7': 3951,
    'NOTE_C8': 4186,
    'NOTE_CS8': 4435,
    'NOTE_D8': 4699,
    'NOTE_DS8': 4978,
    'REST': 0
}

SQUARE_CHANNELS = 3


# Get note bytes from float frequency and integer duration in millis
def note_to_bytes(frequency, duration):
    data = bytearray()
    period = int(44000 / frequency) if frequency else 0  # Period in samples
    i = 0
    while duration > 0:
        data += bytearray(4)
        length = min(duration, 2**12)
        data[i] = (length >> 8) & 0xFF
        data[i + 1] = length & 0xFF
        data[i + 2] = (period >> 8) & 0xFF
        data[i + 3] = period & 0xFF
        i += 4
        duration -= 2**12
    return data


def main():
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('input', help='The input file')
    parser.add_argument('output', help='The output file')
    parser.add_argument('-m', '--mode', default='midi', choices=['arduino', 'midi'], help='The type of input file')
    parser.add_argument('-t', '--tempo', type=int, help='Override music tempo')
    args = parser.parse_args()

    tracks = []

    if args.mode == 'arduino':
        tempo = None

        notes = []
        for line in open(args.input):
            cleaned = line.replace(' ', '')
            tempo_match = re.search(r'tempo=(\d+)', cleaned)
            if tempo_match:
                tempo = int(tempo_match[1])
            for match in re.findall(r'(NOTE_[A-G]S?\d|REST),(-?\d+)', cleaned):
                notes.append({
                    'note': match[0],
                    'length': match[1]
                })

        if args.tempo:
            tempo = args.tempo

        if tempo is None:
            print('Warning: Could not determine song tempo, defaulting to 120 BPM')
            tempo = 120

        whole_note = int(240000 / tempo)  # Whole note length in millis
        data = bytearray()
        for i in range(len(notes)):
            length = int(notes[i]['length'])
            duration = int(whole_note * (1 / abs(length)) * (3 / 2 if length < 0 else 1))
            data += note_to_bytes(NOTES[notes[i]['note']], duration)
        data += bytearray(4)
        tracks.append(data)
    else:
        channels = [[] for _ in range(SQUARE_CHANNELS)]
        midi_data = pretty_midi.PrettyMIDI(args.input)
        for instrument in midi_data.instruments:
            if instrument.is_drum:
                continue
            for note in instrument.notes:
                for channel in channels:
                    placed = False
                    for i in range(len(channel)):
                        if note.end <= channel[i].start and (i == 0 or channel[i - 1].end <= note.start):
                            channel.insert(i, note)
                            placed = True
                            break
                    else:
                        if len(channel) == 0 or note.start >= channel[-1].end:
                            channel.append(note)
                            break
                    if placed:
                        break
                else:
                    print(f"Warning: Insufficient channels, dropped note at {round(note.start, 2)} seconds")
        for channel in channels:
            data = bytearray()
            for i in range(len(channel)):
                note = channel[i]
                data += note_to_bytes(pretty_midi.note_number_to_hz(channel[i].pitch), int((note.end - note.start) * 1000))
                if i < len(channel) - 1 and (rest := int((channel[i + 1].start - note.end) * 1000)) > 0:
                    data += note_to_bytes(0, rest)
            data += bytearray(2)
            tracks.append(data)

    f = open(args.output, "wb")
    offset = 2 * SQUARE_CHANNELS
    for i in range(SQUARE_CHANNELS):
        if i < len(tracks):
            f.write(bytes([offset >> 8, offset & 0xFF]))
            offset += len(tracks[i])
        else:
            f.write(bytes([0, 0]))
    for track in tracks:
        f.write(track)
    f.close()


if __name__ == '__main__':
    main()
