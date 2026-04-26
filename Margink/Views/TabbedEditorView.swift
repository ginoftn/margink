import SwiftUI
import UniformTypeIdentifiers

struct TabbedEditorView: View {
    @Bindable var tabManager: TabManager

    @State private var isDragTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            Theme.divider.frame(height: 0.5)

            if tabManager.tabs.isEmpty {
                emptyState
            } else {
                ZStack {
                    ForEach(tabManager.tabs) { tab in
                        ContentView(tab: tab)
                            .opacity(tab.id == tabManager.selectedTabId ? 1 : 0)
                            .allowsHitTesting(tab.id == tabManager.selectedTabId)
                    }
                }
            }
        }
        .background(Theme.editorBackground)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                TabBarView(tabManager: tabManager)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFileRequest)) { notif in
            if let path = notif.userInfo?["path"] as? String {
                tabManager.addTab(filePath: path)
            }
        }
        .onAppear {
            configureTitleBar()
        }
    }

    private func configureTitleBar() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.windows.first {
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.backgroundColor = NSColor(Theme.tabBarBackground)
                window.isMovableByWindowBackground = true
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "doc.text")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(Theme.textTertiary)

            Text("Margink")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Theme.textPrimary)

            Text("Open a file or drag it here")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)

            Button("Open a file...") {
                openFile()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.inputBackground)
            )
            .foregroundStyle(Theme.textPrimary)
            .font(.system(size: 13))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(isDragTargeted ? Theme.accent.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }

    private func openFile() {
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

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url,
                   url.pathExtension == "md" ||
                   UTType(filenameExtension: url.pathExtension)?.conforms(to: .plainText) == true {
                    DispatchQueue.main.async {
                        tabManager.addTab(filePath: url.path)
                    }
                }
            }
        }
        return true
    }
}
