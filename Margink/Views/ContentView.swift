import SwiftUI
import ClaudeCodeSDK
import os.log

private let viewLogger = Logger(subsystem: "com.margink.app", category: "ContentView")

struct ContentView: View {
    @Bindable var tab: TabModel

    @State private var fileChangedSinceLastMessage = false
    @State private var saveTask: Task<Void, Never>?
    @State private var isReloadingFromDisk = false

    @State private var claudeService: ClaudeService?
    @State private var serviceError: String?
    @State private var conversationStore = ConversationStore()
    @State private var fontSize: CGFloat = 14
    @State private var themeName = ThemeManager.shared.currentThemeName
    @State private var fileWatcher: FileWatcher?

    var body: some View {
        Group {
            if let error = serviceError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.unsaved)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.editorBackground)
            } else {
                HSplitView {
                    EditorPane(
                        text: $tab.text,
                        fileName: tab.fileName,
                        fontSize: fontSize,
                        isSaved: tab.isSaved
                    )
                    .frame(minWidth: 350)

                    if tab.isChatVisible {
                        ChatPane(
                            messages: tab.messages,
                            inputText: $tab.inputText,
                            isLoading: claudeService?.isLoading ?? false,
                            fontSize: fontSize,
                            onSend: sendMessage
                        )
                        .frame(minWidth: 280, idealWidth: 350)
                    }
                }
            }
        }
        .onAppear {
            initService()
            startFileWatcher()
            guard !tab.isLoaded else { return }
            loadFile()
            loadPersistedMessages()
            tab.isLoaded = true
        }
        .onDisappear {
            fileWatcher?.stop()
        }
        .onChange(of: tab.text) {
            guard !isReloadingFromDisk else { return }
            fileChangedSinceLastMessage = true
            tab.isSaved = false
            scheduleSave()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
            fontSize = min(fontSize + 2, 32)
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
            fontSize = max(fontSize - 2, 10)
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomReset)) { _ in
            fontSize = 14
        }
        .onReceive(NotificationCenter.default.publisher(for: .themeChanged)) { _ in
            themeName = ThemeManager.shared.currentThemeName
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleChat)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                tab.isChatVisible.toggle()
            }
        }
        .id(themeName)
    }

    private func initService() {
        do {
            claudeService = try ClaudeService()
        } catch {
            let detail = (error as? ClaudeCodeError)?.localizedDescription ?? String(describing: error)
            viewLogger.error("[Margink] Service init error: \(detail)")
            serviceError = detail
        }
    }

    private func loadFile() {
        tab.text = (try? String(contentsOfFile: tab.filePath, encoding: .utf8)) ?? ""
        fileChangedSinceLastMessage = false
        tab.isSaved = true
    }

    private func loadPersistedMessages() {
        tab.messages = conversationStore.loadMessages(for: tab.filePath)
    }

    private func sendMessage() {
        let userMessage = tab.inputText.trimmingCharacters(in: .whitespaces)
        guard !userMessage.isEmpty, let service = claudeService else { return }

        tab.messages.append(ChatMessage(role: .user, content: userMessage))
        conversationStore.saveMessages(tab.messages, for: tab.filePath)
        tab.inputText = ""

        let currentText = tab.text
        let changed = fileChangedSinceLastMessage
        fileChangedSinceLastMessage = false

        Task {
            do {
                let result: (response: String, sessionId: String?)

                if let existingSessionId = conversationStore.loadSession(for: tab.filePath)?.sessionId {
                    result = try await service.sendFollowUp(
                        sessionId: existingSessionId,
                        filePath: tab.filePath,
                        message: userMessage,
                        fileContent: currentText,
                        fileChanged: changed
                    )
                } else {
                    result = try await service.sendFirst(
                        filePath: tab.filePath,
                        fileContent: currentText,
                        message: userMessage
                    )
                }

                tab.messages.append(ChatMessage(role: .assistant, content: result.response))
                conversationStore.saveMessages(tab.messages, for: tab.filePath)

                if let sid = result.sessionId {
                    var entry = conversationStore.loadSession(for: tab.filePath)
                        ?? SessionEntry(filePath: tab.filePath, sessionId: nil, lastUsed: Date(), contextHash: nil)
                    entry.sessionId = sid
                    entry.lastUsed = Date()
                    conversationStore.saveSession(entry)
                }
            } catch {
                let errorDetail: String
                if let claudeError = error as? ClaudeCodeError {
                    errorDetail = claudeError.localizedDescription
                } else {
                    errorDetail = String(describing: error)
                }
                viewLogger.error("[Margink] Claude error: \(errorDetail)")
                tab.messages.append(ChatMessage(role: .assistant, content: "Error: \(errorDetail)"))
                conversationStore.saveMessages(tab.messages, for: tab.filePath)
            }
        }
    }

    private func startFileWatcher() {
        guard !tab.isUntitled else { return }
        let watcher = FileWatcher(filePath: tab.filePath) { [self] in
            reloadFromDisk()
        }
        watcher.start()
        fileWatcher = watcher
    }

    private func reloadFromDisk() {
        guard let newContent = try? String(contentsOfFile: tab.filePath, encoding: .utf8) else { return }
        if newContent != tab.text {
            viewLogger.info("[Margink] File changed externally, reloading: \(tab.fileName)")
            isReloadingFromDisk = true
            tab.text = newContent
            tab.isSaved = true
            isReloadingFromDisk = false
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            fileWatcher?.pause()
            try? tab.text.write(toFile: tab.filePath, atomically: true, encoding: .utf8)
            fileWatcher?.resume()
            await MainActor.run { tab.isSaved = true }
        }
    }
}
