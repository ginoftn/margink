import Foundation
import CryptoKit
import os.log

private let storeLogger = Logger(subsystem: "com.margink.app", category: "ConversationStore")

struct SessionEntry: Codable {
    let filePath: String
    var sessionId: String?
    var lastUsed: Date
    var contextHash: String?
}

@Observable
class ConversationStore {
    private let sessionsDir: URL
    private let appSupportDir: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.appSupportDir = appSupport.appendingPathComponent("Margink")
        self.sessionsDir = appSupportDir.appendingPathComponent("sessions")
        try? FileManager.default.createDirectory(at: sessionsDir, withIntermediateDirectories: true)
    }

    func sessionDir(for filePath: String) -> URL {
        let hash = SHA256.hash(data: Data(filePath.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        let dir = sessionsDir.appendingPathComponent(hashString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func loadSession(for filePath: String) -> SessionEntry? {
        let url = sessionDir(for: filePath).appendingPathComponent("session.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SessionEntry.self, from: data)
    }

    func saveSession(_ entry: SessionEntry) {
        let url = sessionDir(for: entry.filePath).appendingPathComponent("session.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(entry) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func loadMessages(for filePath: String) -> [ChatMessage] {
        let url = sessionDir(for: filePath).appendingPathComponent("messages.json")
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([ChatMessage].self, from: data)) ?? []
    }

    func saveMessages(_ messages: [ChatMessage], for filePath: String) {
        let url = sessionDir(for: filePath).appendingPathComponent("messages.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(messages) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func sha256(of string: String) -> String {
        let hash = SHA256.hash(data: Data(string.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
