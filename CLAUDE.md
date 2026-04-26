# CLAUDE.md -- Margink

Margink is a markdown editor for macOS with integrated AI assistance via Claude Code SDK.

## Architecture

- **13 Swift files** in Margink/
- **Models**: ChatMessage (chat data), TabModel + TabManager (document tabs)
- **Views**: MarginkApp (entry), ContentView (split editor+chat), EditorPane (header+editor), MarkdownTextView (NSTextView wrapper with live markdown styling), ChatPane (AI chat), TabBarView (tab strip), TabbedEditorView (tab container)
- **Services**: ClaudeService (ClaudeCodeSDK wrapper), ConversationStore (session persistence in ~/Library/Application Support/Margink/)
- **Theme system**: 4 themes (Ink, Parchment, Midnight, Desert) via ThemeColors protocol

## Key Features

- Live markdown rendering (bold, italic, strikethrough, headings) without modifying the raw text
- Tabbed editing with drag-and-drop support
- Integrated AI chat per document via ClaudeCodeSDK
- Conversation persistence per file (SHA256 hash-based session directories)
- Auto-save (2s debounce)
- 4 color themes with system preference persistence
- Find/Replace via native NSTextFinder

## Dependencies

- ClaudeCodeSDK (Swift Package, requires Claude Code CLI installed at ~/.local/bin/claude)

## Build

Requires XcodeGen to generate the .xcodeproj from project.yml:
```
brew install xcodegen
xcodegen generate
open Margink.xcodeproj
```

Or create a new macOS App project in Xcode, add the Swift files, and add ClaudeCodeSDK via SPM.

## Origin

Forked from NoesisEditor (Gino's personal writing IDE). Stripped of NOESIS-specific features (StudioService, ContextBuilder, progress capture). Designed as a standalone public product.
