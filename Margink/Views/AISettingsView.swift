import SwiftUI

struct AISettingsView: View {
    @State private var settings = AISettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.editorBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textTertiary)
                            .frame(width: 22, height: 22)
                            .background(
                                Circle().fill(Theme.inputBackground)
                            )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                Theme.divider.frame(height: 0.5)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // System Prompt
                        settingsSection("System Prompt") {
                            TextEditor(text: $settings.systemPrompt)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Theme.textPrimary)
                                .frame(minHeight: 80, maxHeight: 140)
                                .scrollContentBackground(.hidden)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Theme.chatBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Theme.divider, lineWidth: 0.5)
                                )
                        }

                        // Max Turns
                        settingsSection("Max Turns") {
                            HStack(spacing: 12) {
                                ForEach([1, 3, 5, 10], id: \.self) { value in
                                    Button {
                                        settings.maxTurns = value
                                    } label: {
                                        Text("\(value)")
                                            .font(.system(size: 12, weight: settings.maxTurns == value ? .semibold : .regular, design: .monospaced))
                                            .foregroundStyle(settings.maxTurns == value ? Theme.editorBackground : Theme.textSecondary)
                                            .frame(width: 36, height: 28)
                                            .background(
                                                RoundedRectangle(cornerRadius: 5)
                                                    .fill(settings.maxTurns == value ? Theme.accent : Theme.chatBackground)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }

                                Text("tool-use rounds per message")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }

                        Theme.divider.frame(height: 0.5).padding(.horizontal, -24)

                        // Tool Permissions
                        settingsSection("Tool Permissions") {
                            VStack(alignment: .leading, spacing: 10) {
                                toolToggle("Edit", description: "Modify files on disk", isOn: $settings.allowEdit)
                                toolToggle("Write", description: "Create new files", isOn: $settings.allowWrite)
                                toolToggle("Bash", description: "Run shell commands", isOn: $settings.allowBash)
                            }

                            Text("By default, Claude can only read your document and respond in chat.")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textTertiary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }

                Theme.divider.frame(height: 0.5)

                // Footer
                HStack {
                    Button {
                        settings.resetToDefaults()
                    } label: {
                        Text("Reset")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.editorBackground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Theme.accent)
                            )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.return, modifiers: [])
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
        }
        .frame(width: 440, height: 460)
    }

    // MARK: - Components

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.8)

            content()
        }
    }

    private func toolToggle(_ name: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()
        }
    }
}
