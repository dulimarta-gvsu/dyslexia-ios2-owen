//
//  dyslexiaApp.swift
//  dyslexia
//

import SwiftUI

@main
struct dyslexiaApp: App {
    var body: some Scene {
        WindowGroup {
            let viewModel = AppViewModel()
            ContentView(viewModel: viewModel)
        }
    }
}
