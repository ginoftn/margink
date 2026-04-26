import SwiftUI

struct ChatPane: View {
    let messages: [ChatMessage]
    @Binding var inputText: String
    let isLoading: Bool
    let fontSize: CGFloat
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text("AI")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if !messages.isEmpty {
                    Text("\(messages.count) msg")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(Theme.chatBackground)

            Theme.divider.frame(height: 0.5)

            ScrollViewReader { proxy in
                ScrollView {
                    if messages.isEmpty && !isLoading {
                        VStack(spacing: 12) {
                            Spacer(minLength: 60)
                            Image(systemName: "text.bubble")
                                .font(.system(size: 28))
                                .foregroundStyle(Theme.textTertiary)
                            Text("Ask a question about your text")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textTertiary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            ForEach(messages) { message in
                                MessageBubble(message: message, fontSize: fontSize)
                                    .id(message.id)
                            }
                            if isLoading {
                                LoadingIndicator()
                                    .id("loading-indicator")
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                }
                .background(Theme.chatBackground)
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isLoading) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        if isLoading {
                            proxy.scrollTo("loading-indicator", anchor: .bottom)
                        } else if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Theme.divider.frame(height: 0.5)

            HStack(spacing: 10) {
                TextField("Message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: fontSize))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1...5)
                    .onSubmit { onSend() }

                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
                            ? Theme.textTertiary
                            : Theme.accent
                        )
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.inputBackground)
        }
        .background(Theme.chatBackground)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let fontSize: CGFloat
    @State private var isHovered = false

    private var isUser: Bool { message.role == .user }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 3) {
            Text(isUser ? "You" : "AI")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isUser ? Theme.textTertiary : Theme.accent.opacity(0.7))

            Text(isUser ? AttributedString(message.content) : markdownContent)
                .font(.system(size: fontSize))
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isUser ? Theme.userBubble : Theme.assistantBubble)
                )
                .overlay(alignment: .topTrailing) {
                    if !isUser && isHovered {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(message.content, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textSecondary)
                                .padding(5)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Theme.inputBackground)
                                )
                        }
                        .buttonStyle(.plain)
                        .offset(x: -6, y: 6)
                    }
                }
                .onHover { isHovered = $0 }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private var markdownContent: AttributedString {
        (try? AttributedString(
            markdown: message.content,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(message.content)
    }
}

// MARK: - Loading Indicator

struct LoadingIndicator: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.accent.opacity(index <= dotCount ? 0.8 : 0.2))
                    .frame(width: 5, height: 5)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}
