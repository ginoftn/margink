import SwiftUI
import Foundation

// MARK: - Single Tab

@MainActor @Observable
final class TabModel: Identifiable {
    let id = UUID()
    let filePath: String

    var text: String = ""
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var fileChangedSinceLastMessage = false
    var isSaved = true
    var isLoaded = false

    var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }

    var currentWordCount: Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    init(filePath: String) {
        self.filePath = filePath
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

    func addTab(filePath: String) {
        if let existing = tabs.first(where: { $0.filePath == filePath }) {
            selectedTabId = existing.id
            return
        }
        let tab = TabModel(filePath: filePath)
        tabs.append(tab)
        selectedTabId = tab.id
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
