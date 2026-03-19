//
//  Letter.swift
//  dyslexia
//

import Foundation

struct Letter: Equatable, Hashable {
    var character: Character = "#"
    var point: Int = 1
    
    var text: String {
        return String(character)
    }
}

extension Array where Element == Letter? {
    func prettyPrint() -> String {
        return self
            .compactMap { $0 }
            .map { String($0.character) }
            .joined(separator: "")
    }
}

extension Array where Element == Letter {
    func prettyPrint() -> String {
        return self
            .map { "\($0.character)" }
            .joined(separator: "")
    }
}
