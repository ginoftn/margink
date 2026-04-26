import SwiftUI
import UniformTypeIdentifiers

struct TabBarView: View {
    @Bindable var tabManager: TabManager

    var body: some View {
        HStack(spacing: 0) {
            Button(action: openFile) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 6)

            Rectangle()
                .fill(Theme.textTertiary.opacity(0.3))
                .frame(width: 1, height: 14)
                .padding(.horizontal, 8)

            HStack(spacing: 0) {
                ForEach(Array(tabManager.tabs.enumerated()), id: \.element.id) { index, tab in
                    if index > 0 {
                        Rectangle()
                            .fill(Theme.textTertiary.opacity(0.3))
                            .frame(width: 1, height: 14)
                            .padding(.horizontal, 4)
                    }

                    TabItemView(
                        tab: tab,
                        isSelected: tab.id == tabManager.selectedTabId,
                        onSelect: { tabManager.selectTab(tab.id) },
                        onClose: { tabManager.closeTab(tab.id) }
                    )
                }
            }

            Spacer()
        }
        .focusEffectDisabled()
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
}

// MARK: - Single Tab Item

struct TabItemView: View {
    let tab: TabModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false
    @State private var isCloseHovered = false

    private var shortName: String {
        let name = tab.fileName
        if let dot = name.lastIndex(of: ".") {
            return String(name[name.startIndex..<dot])
        }
        return name
    }

    var body: some View {
        HStack(spacing: 4) {
            if !tab.isSaved {
                Circle()
                    .fill(Theme.unsaved)
                    .frame(width: 5, height: 5)
            }

            Text(shortName)
                .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textTertiary)
                .lineLimit(1)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(isCloseHovered ? Theme.textPrimary : Theme.textTertiary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .onHover { isCloseHovered = $0 }
            .opacity(isHovered || isSelected ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .focusEffectDisabled()
        .onHover { isHovered = $0 }
        .onTapGesture { onSelect() }
    }
}
