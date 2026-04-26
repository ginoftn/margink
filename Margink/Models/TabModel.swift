import SwiftUI
import AppKit
import Foundation
import UniformTypeIdentifiers

// MARK: - Single Tab

@MainActor @Observable
final class TabModel: Identifiable {
    let id = UUID()
    var filePath: String
    var isUntitled: Bool

    var text: String = ""
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var fileChangedSinceLastMessage = false
    var isSaved = true
    var isLoaded = false
    var isChatVisible = true

    var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }

    var currentWordCount: Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    init(filePath: String, isUntitled: Bool = false) {
        self.filePath = filePath
        self.isUntitled = isUntitled
    }
}

// MARK: - Tab Manager

@MainActor @Observable
final class TabManager {
    var tabs: [TabModel] = []
    var selectedTabId: UUID?

    var selectedTab: TabModel? {
        tabs.first { $0.id == selectedTabId }
    }

    var isEmpty: Bool { tabs.isEmpty }

    private static var untitledCounter = 0

    func addTab(filePath: String) {
        if let existing = tabs.first(where: { $0.filePath == filePath }) {
            selectedTabId = existing.id
            return
        }
        let tab = TabModel(filePath: filePath)
        tabs.append(tab)
        selectedTabId = tab.id
    }

    func newUntitledTab() {
        TabManager.untitledCounter += 1
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("Margink", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let name = TabManager.untitledCounter == 1 ? "Untitled.md" : "Untitled \(TabManager.untitledCounter).md"
        let path = dir.appendingPathComponent(name).path
        FileManager.default.createFile(atPath: path, contents: nil)
        let tab = TabModel(filePath: path, isUntitled: true)
        tab.isLoaded = true
        tab.isSaved = true
        tabs.append(tab)
        selectedTabId = tab.id
    }

    func saveAs(tab: TabModel) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = tab.fileName
        panel.title = "Save As"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? tab.text.write(to: url, atomically: true, encoding: .utf8)
        tab.filePath = url.path
        tab.isUntitled = false
        tab.isSaved = true
    }

    func closeTab(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        let wasSelected = selectedTabId == id
        tabs.remove(at: index)

        if wasSelected {
            if tabs.isEmpty {
                selectedTabId = nil
            } else {
                let newIndex = min(index, tabs.count - 1)
                selectedTabId = tabs[newIndex].id
            }
        }
    }

    func selectTab(_ id: UUID) {
        selectedTabId = id
    }

    func moveTab(from source: Int, to destination: Int) {
        guard source != destination,
              source >= 0, source < tabs.count,
              destination >= 0, destination < tabs.count else { return }
        let tab = tabs.remove(at: source)
        tabs.insert(tab, at: destination)
    }
}
