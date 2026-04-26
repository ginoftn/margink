import SwiftUI
import AppKit

/// NSTextView wrapper that renders **bold** and *italic* markdown markers visually
/// while preserving them in the raw text (the .md file stays intact).
struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.backgroundColor = NSColor(Theme.editorBackground)
        textView.insertionPointColor = NSColor(Theme.accent)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.usesFindBar = true

        textView.textContainerInset = NSSize(width: 16, height: 12)
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]

        textView.delegate = context.coordinator

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(Theme.editorBackground)
        scrollView.scrollerStyle = .overlay

        textView.string = text
        context.coordinator.applyMarkdownStyling(to: textView, fontSize: fontSize)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        context.coordinator.parent = self

        textView.backgroundColor = NSColor(Theme.editorBackground)
        scrollView.backgroundColor = NSColor(Theme.editorBackground)
        textView.insertionPointColor = NSColor(Theme.accent)

        if context.coordinator.lastFontSize != fontSize {
            context.coordinator.lastFontSize = fontSize
            context.coordinator.needsRestyling = true
        }

        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            context.coordinator.applyMarkdownStyling(to: textView, fontSize: fontSize)
        } else if context.coordinator.needsRestyling {
            context.coordinator.applyMarkdownStyling(to: textView, fontSize: fontSize)
            context.coordinator.needsRestyling = false
        }
    }

    // MARK: - Coordinator

    @MainActor class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextView
        private var isUpdating = false
        var needsRestyling = false
        var lastFontSize: CGFloat = 0

        init(_ parent: MarkdownTextView) {
            self.parent = parent
            self.lastFontSize = parent.fontSize
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }
            isUpdating = true
            parent.text = textView.string
            let cursorLocation = textView.selectedRange().location
            applyParagraphStyling(to: textView, at: cursorLocation, fontSize: parent.fontSize)
            isUpdating = false
        }

        func applyParagraphStyling(to textView: NSTextView, at editLocation: Int, fontSize: CGFloat) {
            let nsString = textView.string as NSString
            guard nsString.length > 0 else { return }

            let clampedLocation = min(max(0, editLocation), nsString.length - 1)
            let paragraphRange = nsString.paragraphRange(for: NSRange(location: clampedLocation, length: 0))

            let storage = textView.textStorage!
            let selectedRanges = textView.selectedRanges

            storage.beginEditing()
            applyStyles(to: storage, in: paragraphRange, fullText: textView.string, fontSize: fontSize)
            storage.endEditing()

            textView.selectedRanges = selectedRanges
        }

        func applyMarkdownStyling(to textView: NSTextView, fontSize: CGFloat) {
            let fullText = textView.string
            guard !fullText.isEmpty else { return }

            let storage = textView.textStorage!
            let fullRange = NSRange(location: 0, length: storage.length)

            let selectedRanges = textView.selectedRanges
            let scrollView = textView.enclosingScrollView
            let visibleRect = scrollView?.contentView.bounds

            storage.beginEditing()
            applyStyles(to: storage, in: fullRange, fullText: fullText, fontSize: fontSize)
            storage.endEditing()

            textView.selectedRanges = selectedRanges
            if let visibleRect = visibleRect {
                scrollView?.contentView.scroll(visibleRect.origin)
            }
        }

        private func applyStyles(to storage: NSTextStorage, in range: NSRange, fullText: String, fontSize: CGFloat) {
            let baseFont = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            let baseColor = NSColor(Theme.textPrimary)

            storage.addAttribute(.font, value: baseFont, range: range)
            storage.addAttribute(.foregroundColor, value: baseColor, range: range)

            let markerColor = NSColor(Theme.textTertiary)

            // Bold: **text**
            let boldPattern = try! NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*", options: [])
            let boldFont = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)

            for match in boldPattern.matches(in: fullText, range: range) {
                let contentRange = match.range(at: 1)
                storage.addAttribute(.font, value: boldFont, range: contentRange)

                let openRange = NSRange(location: match.range.location, length: 2)
                let closeRange = NSRange(location: match.range.location + match.range.length - 2, length: 2)
                storage.addAttribute(.foregroundColor, value: markerColor, range: openRange)
                storage.addAttribute(.foregroundColor, value: markerColor, range: closeRange)
            }

            // Italic: *text* (but not **text**)
            let italicPattern = try! NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", options: [])
            let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)

            for match in italicPattern.matches(in: fullText, range: range) {
                let contentRange = match.range(at: 1)
                storage.addAttribute(.font, value: italicFont, range: contentRange)

                let openRange = NSRange(location: match.range.location, length: 1)
                let closeRange = NSRange(location: match.range.location + match.range.length - 1, length: 1)
                storage.addAttribute(.foregroundColor, value: markerColor, range: openRange)
                storage.addAttribute(.foregroundColor, value: markerColor, range: closeRange)
            }

            // Strikethrough: ~~text~~
            let strikePattern = try! NSRegularExpression(pattern: "~~(.+?)~~", options: [])

            for match in strikePattern.matches(in: fullText, range: range) {
                let contentRange = match.range(at: 1)
                storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: contentRange)
                storage.addAttribute(.strikethroughColor, value: baseColor, range: contentRange)

                let openRange = NSRange(location: match.range.location, length: 2)
                let closeRange = NSRange(location: match.range.location + match.range.length - 2, length: 2)
                storage.addAttribute(.foregroundColor, value: markerColor, range: openRange)
                storage.addAttribute(.foregroundColor, value: markerColor, range: closeRange)
            }

            // Headings: # ## ### at line start
            let headingPattern = try! NSRegularExpression(pattern: "^(#{1,3})\\s+(.+)$", options: [.anchorsMatchLines])
            let headingColor = NSColor(Theme.accent)

            for match in headingPattern.matches(in: fullText, range: range) {
                let hashRange = match.range(at: 1)
                let hashCount = hashRange.length
                let textRange = match.range(at: 2)
                let headingSize = fontSize + CGFloat(4 - hashCount) * 2
                let headingFont = NSFont.monospacedSystemFont(ofSize: headingSize, weight: .bold)

                storage.addAttribute(.font, value: headingFont, range: textRange)
                storage.addAttribute(.foregroundColor, value: headingColor, range: textRange)
                storage.addAttribute(.foregroundColor, value: markerColor, range: hashRange)
            }
        }
    }
}
