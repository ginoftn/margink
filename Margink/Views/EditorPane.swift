import SwiftUI

struct EditorPane: View {
    @Binding var text: String
    let fileName: String
    let fontSize: CGFloat
    let isSaved: Bool

    private var wordCount: Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    private var formattedWordCount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "\u{202F}"
        return formatter.string(from: NSNumber(value: wordCount)) ?? "\(wordCount)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isSaved ? Theme.saved : Theme.unsaved)
                    .frame(width: 7, height: 7)

                Text(fileName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)

                Spacer()

                Text("\(formattedWordCount) words")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.textTertiary)

                Text(isSaved ? "Saved" : "Editing...")
                    .font(.system(size: 10))
                    .foregroundStyle(isSaved ? Theme.textTertiary : Theme.unsaved)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(Theme.editorBackground)

            Theme.divider.frame(height: 0.5)

            MarkdownTextView(text: $text, fontSize: fontSize)
                .background(Theme.editorBackground)
        }
        .background(Theme.editorBackground)
    }
}
