//
//  History.swift
//  QuickScribe
//
//  Created by Mike Brevoort on 8/14/23.
//

import Foundation

struct History: CustomStringConvertible, Codable {
    
    private var elements: [HistoryItem] = []
    public let size: Int
    
    var isEmpty: Bool {
        elements.isEmpty
    }
    
    var peek: HistoryItem? {
        elements.first
    }
    
    var description: String {
        if isEmpty { return "FixedQueue of \(size) is empty ..."}
        return "---- Queue of length \(size) start ----\n"
        + elements.map({"\($0)"}).joined(separator: " -> ")
        + "\n---- Queue End ----"
    }
    
    mutating func enqueue(_ value: HistoryItem) {
        if elements.count == self.size {
            _ = self.dequeue()
        }
        elements.append(value)
    }
    
    mutating func dequeue() -> HistoryItem? {
        isEmpty ? nil : elements.removeFirst()
    }
    
    mutating func replace(_ ref: History) {
        self.elements = ref.elements
    }
    
    func list() -> [HistoryItem] {
        elements.reversed()
    }
    
    init(size: Int) {
        self.size = size
    }
    
    init() {
        self.size = 10
    }
}

enum HistoryItemType: Codable {
    case error, transcription
}

class HistoryItem: Identifiable, Codable {
    var type: HistoryItemType = HistoryItemType.transcription
    var body: String
    var time: Date
    
    var description: String {
        "\(type): \(body)"
    }
    
    var friendlyType: String {
        switch self.type {
        case HistoryItemType.error:
            return "Error"
        case HistoryItemType.transcription:
            return "Transcription"
        }
    }
    
    init(_ body: String) {
        self.body = body
        self.type = HistoryItemType.transcription
        self.time = Date()
    }
    
    init(body: String, type: HistoryItemType) {
        self.body = body
        self.type = type
        self.time = Date()
    }
    init(body: String, type: HistoryItemType, time: Date) {
        self.body = body
        self.type = type
        self.time = time
    }
}
