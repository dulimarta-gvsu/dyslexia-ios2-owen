//
//  AppViewModel.swift
//  dyslexia
//

import Foundation
import Combine
import SwiftUI

struct WordRecord: Identifiable, Hashable {
    let id = UUID()
    let word: String
    let points: Int
    let moves: Int
    let durationSeconds: Int
    let date = Date()
}

class AppViewModel: ObservableObject {
    private let TAG = "AppViewModel"
    
    let wordStock = [
        "helium", "oxygen", "hydrogen", "carbon", "nitrogen", "neon",
        "sodium", "magnesium", "aluminum", "silicon", "phosphorus", "sulfur",
        "chlorine", "argon", "potassium", "calcium", "titanium", "vanadium",
        "chromium", "manganese", "iron", "cobalt", "nickel", "copper",
        "zinc", "arsenic", "bromine", "krypton", "silver", "tin",
        "iodine", "xenon", "platinum", "gold", "mercury", "lead"
    ]
    
    // Make this internal so it can be accessed from other files
    let letterScore: [Character: Int] = [
        "A": 1, "B": 3, "C": 3, "D": 2, "E": 1,
        "F": 4, "G": 2, "H": 4, "I": 1, "J": 8,
        "K": 5, "L": 1, "M": 3, "N": 1, "O": 1,
        "P": 3, "Q": 10, "R": 1, "S": 1, "T": 1,
        "U": 1, "V": 4, "W": 4, "X": 8, "Y": 4, "Z": 10
    ]
    
    @Published var selectedWord: String = ""
    @Published var letters: [Letter?] = []
    @Published var removedLetter: Letter? = nil
    @Published var removedIndex: Int? = nil
    @Published var moves: Int = 0
    @Published var totalScore: Int = 0
    @Published var timeElapsed: Int = 0
    @Published var isWordUnscrambled: Bool = false
    @Published var gameHistory: [WordRecord] = []
    @Published var showCongrats: Bool = false
    @Published var wordLengthMin: Int = 3
    @Published var wordLengthMax: Int = 7
    @Published var red: Double = 76/255.0
    @Published var green: Double = 175/255.0
    @Published var blue: Double = 80/255.0
    @Published var formattedTime: String = "0.0s"
    
    var letterColor: Color {
        Color(red: red, green: green, blue: blue)
    }
    
    private var timer: Timer?
    private var startTime: Date?
    
    init() {
        selectNewWord()
    }
    
    private func addGameRecord(word: String, points: Int, moves: Int, durationMillis: Int) {
        let record = WordRecord(
            word: word,
            points: points,
            moves: moves,
            durationSeconds: durationMillis / 1000
        )
        gameHistory.append(record)
    }
    
    func sortByWord() {
        gameHistory.sort { $0.word < $1.word }
    }
    
    func sortByPoints() {
        gameHistory.sort { $0.points > $1.points }
    }
    
    func sortByMoves() {
        gameHistory.sort { $0.moves < $1.moves }
    }
    
    func sortByDuration() {
        gameHistory.sort { $0.durationSeconds > $1.durationSeconds }
    }
    
    func updateWordLengthRange(min: Int, max: Int) {
        wordLengthMin = min
        wordLengthMax = max
    }
    
    func updateRed(_ value: Double) { red = value }
    func updateGreen(_ value: Double) { green = value }
    func updateBlue(_ value: Double) { blue = value }
    
    func selectNewWord() {
        if !selectedWord.isEmpty && !isWordUnscrambled {
            let duration = Int(Date().timeIntervalSince(startTime ?? Date()) * 1000)
            addGameRecord(word: selectedWord, points: 0, moves: moves, durationMillis: duration)
        }
        
        let filtered = wordStock.filter { $0.count >= wordLengthMin && $0.count <= wordLengthMax }
        let newWord = (filtered.isEmpty ? wordStock : filtered).randomElement()!.uppercased()
        
        selectedWord = newWord
        let letterList = newWord.map { char -> Letter? in
            Letter(character: char, point: letterScore[char] ?? 1)
        }.shuffled()
        letters = letterList
        removedLetter = nil
        removedIndex = nil
        moves = 0
        timeElapsed = 0
        isWordUnscrambled = false
        showCongrats = false
        startTime = Date()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        if let start = startTime, !isWordUnscrambled {
            timeElapsed = Int(Date().timeIntervalSince(start) * 1000)
            let seconds = Double(timeElapsed) / 1000.0
            formattedTime = String(format: "%.1fs", seconds)
        }
    }
    
    func removeLetterAt(pos: Int) {
        guard pos >= 0 && pos < letters.count else { return }
        removedLetter = letters[pos]
        removedIndex = pos
        letters[pos] = nil
    }
    
    func unremoveLetter() {
        guard let removed = removedLetter,
              let originalIndex = removedIndex else { return }
        
        let currentBlankIndex = letters.firstIndex { $0 == nil }
        
        if let blankIndex = letters.firstIndex(where: { $0 == nil }) {
            letters[blankIndex] = removed
        }
        
        if currentBlankIndex != originalIndex {
            moves += 1
        }
        
        removedLetter = nil
        removedIndex = nil
        
        checkIfWordUnscrambled()
    }
    
    func swapLetters(aPos: Int, bPos: Int) {
        guard aPos >= 0 && aPos < letters.count &&
              bPos >= 0 && bPos < letters.count &&
              aPos != bPos else { return }
        
        let temp = letters[aPos]
        letters[aPos] = letters[bPos]
        letters[bPos] = temp
        moves += 1
        
        checkIfWordUnscrambled()
    }
    
    private func checkIfWordUnscrambled() {
        let currentWord = letters.compactMap { $0?.character }.map { String($0) }.joined()
        
        if currentWord == selectedWord && !isWordUnscrambled {
            isWordUnscrambled = true
            showCongrats = true
            
            let wordScore = selectedWord.reduce(0) { $0 + (letterScore[$1] ?? 1) }
            totalScore += wordScore
            
            let duration = Int(Date().timeIntervalSince(startTime ?? Date()) * 1000)
            timeElapsed = duration
            addGameRecord(word: selectedWord, points: wordScore, moves: moves, durationMillis: duration)
            
            timer?.invalidate()
        }
    }
    
    func skipWord() {
        if !selectedWord.isEmpty && !isWordUnscrambled {
            let duration = Int(Date().timeIntervalSince(startTime ?? Date()) * 1000)
            addGameRecord(word: selectedWord, points: 0, moves: moves, durationMillis: duration)
        }
        selectNewWord()
    }
    
    func rearrange(to: [Letter]) {
        self.letters = to.map { $0 }
        checkIfWordUnscrambled()
    }
    
    func startNewGame() {
        selectNewWord()
    }
}
