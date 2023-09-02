//
//  History.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/14/23.
//

import Foundation

struct HistoryModel: CustomStringConvertible, Codable {
    
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
    
    mutating func replace(_ ref: HistoryModel) {
        self.elements = ref.elements
    }
    
    mutating func delete(_ item: HistoryItem) {
        self.elements = self.elements.filter{ $0.time != item.time && $0.body != item.body}
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
    var duration: CFAbsoluteTime
    
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
        self.duration = 0;
    }
    
    init(body: String, type: HistoryItemType) {
        self.body = body
        self.type = type
        self.time = Date()
        self.duration = 0;
    }
    
    init(body: String, type: HistoryItemType, time: Date) {
        self.body = body
        self.type = type
        self.time = time
        self.duration = 0;
    }

    init(body: String, type: HistoryItemType, time: Date, duration: CFAbsoluteTime) {
        self.body = body
        self.type = type
        self.time = time
        self.duration = duration;
    }

}
