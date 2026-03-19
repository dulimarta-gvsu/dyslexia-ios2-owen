//
//  ContentView.swift
//  dyslexia
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var letters: [Letter] = []
    @State private var showingHistory = false
    @State private var showingSettings = false
    
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button {
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .padding(8)
                            .background(.white)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 5) {
                        HStack(spacing: 15) {
                            Label("\(viewModel.moves)", systemImage: "arrow.left.arrow.right")
                            Label(viewModel.formattedTime, systemImage: "timer")
                        }
                        .font(.headline)
                        
                        Text("Total Score: \(viewModel.totalScore)")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .bold()
                    }
                    
                    Spacer()
                    
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.title2)
                            .padding(8)
                            .background(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 30) {
                    Text("Unscramble the word!")
                        .font(.title2)
                        .bold()
                    
                    LetterGroup(letters: $letters,
                              onRearrangeLetters: { arr in
                        viewModel.rearrange(to: arr)
                    })
                    .environmentObject(viewModel)
                    
                    Button("Skip Word") {
                        viewModel.skipWord()
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
                
                Spacer()
                
                Button("New Word") {
                    viewModel.selectNewWord()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .font(.title2)
                .padding(.bottom)
            }
            .padding()
            .background(Color.yellow)
            .navigationTitle("Dyslexia Game")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingHistory) {
                HistoryListView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .alert("Congratulations! 🎉", isPresented: $viewModel.showCongrats) {
                Button("Play Again") {
                    viewModel.selectNewWord()
                }
                Button("View History") {
                    showingHistory = true
                }
            } message: {
                let wordScore = viewModel.selectedWord.reduce(0) { $0 + (viewModel.letterScore[$1] ?? 1) }
                Text("You solved '\(viewModel.selectedWord)' in \(viewModel.moves) moves and \(String(format: "%.1f", Double(viewModel.timeElapsed)/1000.0)) seconds!\nWord score: \(wordScore)")
            }
            .onReceive(viewModel.$letters) { newValue in
                letters = newValue.compactMap { $0 }
            }
        }
    }
}

struct HistoryListView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button("Word") {
                        viewModel.sortByWord()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Points") {
                        viewModel.sortByPoints()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Moves") {
                        viewModel.sortByMoves()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Time") {
                        viewModel.sortByDuration()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            
            List(viewModel.gameHistory) { record in
                NavigationLink(value: record) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(record.word)
                                .font(.headline)
                                .bold()
                            HStack {
                                Text("Moves: \(record.moves)")
                                Text("Time: \(record.durationSeconds)s")
                            }
                            .font(.caption)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text("\(record.points) pts")
                                .font(.title3)
                                .bold()
                            Text(record.points > 0 ? "✓" : "✗")
                                .font(.title2)
                                .foregroundColor(record.points > 0 ? .green : .red)
                        }
                    }
                    .padding(8)
                    .background(record.points > 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .navigationTitle("Game History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(for: WordRecord.self) { record in
                HistoryDetailView(record: record)
            }
        }
    }
}

struct HistoryDetailView: View {
    let record: WordRecord
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Text(record.word)
                .font(.system(size: 60, weight: .bold))
                .padding()
                .background(record.points > 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                .cornerRadius(20)
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Points:")
                        .bold()
                    Spacer()
                    Text("\(record.points)")
                }
                HStack {
                    Text("Moves:")
                        .bold()
                    Spacer()
                    Text("\(record.moves)")
                }
                HStack {
                    Text("Time:")
                        .bold()
                    Spacer()
                    Text("\(record.durationSeconds) seconds")
                }
                HStack {
                    Text("Status:")
                        .bold()
                    Spacer()
                    Text(record.points > 0 ? "Completed" : "Incomplete")
                }
                HStack {
                    Text("Date:")
                        .bold()
                    Spacer()
                    Text(record.date.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .font(.title2)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var minLength: Double
    @State private var maxLength: Double
    
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        _minLength = State(initialValue: Double(viewModel.wordLengthMin))
        _maxLength = State(initialValue: Double(viewModel.wordLengthMax))
    }
    
    var body: some View {
        Form {
            Section("Word Length Range") {
                VStack {
                    HStack {
                        Text("Min: \(Int(minLength))")
                        Spacer()
                        Text("Max: \(Int(maxLength))")
                    }
                    
                    HStack {
                        Text("3")
                        Slider(value: $minLength, in: 3...10, step: 1)
                            .onChange(of: minLength) { oldValue, newValue in
                                if newValue > maxLength {
                                    maxLength = newValue
                                }
                                viewModel.updateWordLengthRange(min: Int(newValue), max: Int(maxLength))
                            }
                        Text("10")
                    }
                    
                    HStack {
                        Text("3")
                        Slider(value: $maxLength, in: 3...10, step: 1)
                            .onChange(of: maxLength) { oldValue, newValue in
                                if newValue < minLength {
                                    minLength = newValue
                                }
                                viewModel.updateWordLengthRange(min: Int(minLength), max: Int(newValue))
                            }
                        Text("10")
                    }
                }
            }
            
            Section("Letter Background Color") {
                VStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(viewModel.letterColor)
                        .frame(height: 60)
                        .overlay(
                            Text("Preview")
                                .foregroundColor(.white)
                                .bold()
                                .shadow(radius: 1)
                        )
                    
                    HStack {
                        Text("R")
                            .foregroundColor(.red)
                            .bold()
                        Slider(value: $viewModel.red, in: 0...1)
                            .onChange(of: viewModel.red) { oldValue, newValue in
                                viewModel.updateRed(newValue)
                            }
                        Text("\(Int(viewModel.red * 255))")
                    }
                    
                    HStack {
                        Text("G")
                            .foregroundColor(.green)
                            .bold()
                        Slider(value: $viewModel.green, in: 0...1)
                            .onChange(of: viewModel.green) { oldValue, newValue in
                                viewModel.updateGreen(newValue)
                            }
                        Text("\(Int(viewModel.green * 255))")
                    }
                    
                    HStack {
                        Text("B")
                            .foregroundColor(.blue)
                            .bold()
                        Slider(value: $viewModel.blue, in: 0...1)
                            .onChange(of: viewModel.blue) { oldValue, newValue in
                                viewModel.updateBlue(newValue)
                            }
                        Text("\(Int(viewModel.blue * 255))")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}
