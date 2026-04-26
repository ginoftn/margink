import SwiftUI
import AppKit

extension Notification.Name {
    static let zoomIn = Notification.Name("margink.zoomIn")
    static let zoomOut = Notification.Name("margink.zoomOut")
    static let zoomReset = Notification.Name("margink.zoomReset")
    static let openFileRequest = Notification.Name("margink.openFileRequest")
    static let themeChanged = Notification.Name("margink.themeChanged")
    static let toggleChat = Notification.Name("margink.toggleChat")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            NotificationCenter.default.post(
                name: .openFileRequest,
                object: nil,
                userInfo: ["path": url.path]
            )
        }
    }
}

@MainActor
private func sendFindAction(_ action: NSTextFinder.Action) {
    let item = NSMenuItem()
    item.tag = action.rawValue
    NSApp.sendAction(#selector(NSResponder.performTextFinderAction(_:)), to: nil, from: item)
}

@main
struct MarginkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var tabManager = TabManager()
    @State private var showAISettings = false

    private let cliFilePath: String?

    init() {
        let args = ProcessInfo.processInfo.arguments
        var documentFile: String?
        var i = 1
        while i < args.count {
            let arg = args[i]
            if arg.hasPrefix("-") {
                i += 2 // skip flag + its value
                continue
            }
            if FileManager.default.fileExists(atPath: arg) {
                documentFile = arg
            }
            i += 1
        }
        self.cliFilePath = documentFile
    }

    var body: some Scene {
        WindowGroup {
            TabbedEditorView(tabManager: tabManager)
                .frame(minWidth: 800, minHeight: 500)
                .onAppear {
                    if let filePath = cliFilePath {
                        tabManager.addTab(filePath: filePath)
                    }
                }
                .sheet(isPresented: $showAISettings) {
                    AISettingsView()
                }
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("AI Settings...") {
                    showAISettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(replacing: .newItem) {
                Button("New") {
                    tabManager.newUntitledTab()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Open...") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.plainText]
                    panel.allowsMultipleSelection = true
                    panel.canChooseDirectories = false
                    panel.title = "Open a document"
                    if panel.runModal() == .OK {
                        for url in panel.urls {
                            tabManager.addTab(filePath: url.path)
                        }
                    }
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button("Save As...") {
                    if let tab = tabManager.selectedTab {
                        tabManager.saveAs(tab: tab)
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(tabManager.isEmpty)

                Divider()

                Button("Close Tab") {
                    if let id = tabManager.selectedTabId {
                        tabManager.closeTab(id)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
                .disabled(tabManager.isEmpty)
            }

            CommandGroup(after: .textEditing) {
                Button("Find...") {
                    sendFindAction(.showFindInterface)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Find and Replace...") {
                    sendFindAction(.showReplaceInterface)
                }
                .keyboardShortcut("f", modifiers: [.command, .option])

                Button("Find Next") {
                    sendFindAction(.nextMatch)
                }
                .keyboardShortcut("g", modifiers: .command)

                Button("Find Previous") {
                    sendFindAction(.previousMatch)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .help) {
                Button("Markdown Syntax") {
                    let alert = NSAlert()
                    alert.messageText = "Supported Markdown Syntax"
                    alert.informativeText = """
                    **bold**              ->  bold
                    *italic*              ->  italic
                    ~~strikethrough~~     ->  strikethrough
                    # Heading 1
                    ## Heading 2
                    ### Heading 3

                    Markers stay visible in the raw text (greyed out) -- the .md file is never modified by the rendering.
                    """
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
                .keyboardShortcut("?", modifiers: [.command, .shift])
            }

            CommandGroup(before: .toolbar) {
                Button("Zoom In") {
                    NotificationCenter.default.post(name: .zoomIn, object: nil)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    NotificationCenter.default.post(name: .zoomOut, object: nil)
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Reset Zoom") {
                    NotificationCenter.default.post(name: .zoomReset, object: nil)
                }
                .keyboardShortcut("0", modifiers: .command)

                Divider()

                Menu("Theme") {
                    ForEach(ThemeManager.allThemes, id: \.name) { theme in
                        Button {
                            ThemeManager.shared.currentThemeName = theme.name
                        } label: {
                            HStack {
                                Text(theme.name)
                                if ThemeManager.shared.currentThemeName == theme.name {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Divider()

                Button("Toggle AI Chat") {
                    NotificationCenter.default.post(name: .toggleChat, object: nil)
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }
        }
    }
}
