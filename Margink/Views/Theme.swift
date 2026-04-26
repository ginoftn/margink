import SwiftUI

// MARK: - Theme Protocol

protocol ThemeColors: Sendable {
    var name: String { get }
    var editorBackground: Color { get }
    var chatBackground: Color { get }
    var inputBackground: Color { get }
    var userBubble: Color { get }
    var assistantBubble: Color { get }
    var accent: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }
    var divider: Color { get }
    var saved: Color { get }
    var unsaved: Color { get }
    var tabBarBackground: Color { get }
    var tabActive: Color { get }
    var tabHover: Color { get }
    var tabCloseHover: Color { get }
}

// MARK: - Theme Manager

@MainActor @Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var currentThemeName: String {
        didSet {
            UserDefaults.standard.set(currentThemeName, forKey: "margink.theme")
            NotificationCenter.default.post(name: .themeChanged, object: nil)
        }
    }

    var current: ThemeColors {
        ThemeManager.allThemes.first { $0.name == currentThemeName } ?? InkTheme()
    }

    static let allThemes: [any ThemeColors] = [
        InkTheme(),
        ParchmentTheme(),
        MidnightTheme(),
        DesertTheme()
    ]

    private init() {
        self.currentThemeName = UserDefaults.standard.string(forKey: "margink.theme") ?? "Ink"
    }
}

// MARK: - Static proxy

@MainActor
enum Theme {
    private static var m: ThemeManager { ThemeManager.shared }

    static var editorBackground: Color { m.current.editorBackground }
    static var chatBackground: Color { m.current.chatBackground }
    static var inputBackground: Color { m.current.inputBackground }
    static var userBubble: Color { m.current.userBubble }
    static var assistantBubble: Color { m.current.assistantBubble }
    static var accent: Color { m.current.accent }
    static var textPrimary: Color { m.current.textPrimary }
    static var textSecondary: Color { m.current.textSecondary }
    static var textTertiary: Color { m.current.textTertiary }
    static var divider: Color { m.current.divider }
    static var saved: Color { m.current.saved }
    static var unsaved: Color { m.current.unsaved }
    static var tabBarBackground: Color { m.current.tabBarBackground }
    static var tabActive: Color { m.current.tabActive }
    static var tabHover: Color { m.current.tabHover }
    static var tabCloseHover: Color { m.current.tabCloseHover }
}

// MARK: - Ink (warm dark, default)

struct InkTheme: ThemeColors {
    let name = "Ink"
    let editorBackground = Color(nsColor: NSColor(red: 0.12, green: 0.11, blue: 0.10, alpha: 1.0))
    let chatBackground = Color(nsColor: NSColor(red: 0.14, green: 0.13, blue: 0.12, alpha: 1.0))
    let inputBackground = Color(nsColor: NSColor(red: 0.18, green: 0.17, blue: 0.15, alpha: 1.0))
    let userBubble = Color(nsColor: NSColor(red: 0.20, green: 0.19, blue: 0.17, alpha: 1.0))
    let assistantBubble = Color(nsColor: NSColor(red: 0.16, green: 0.15, blue: 0.14, alpha: 1.0))
    let accent = Color(nsColor: NSColor(red: 0.85, green: 0.65, blue: 0.30, alpha: 1.0))
    let textPrimary = Color(nsColor: NSColor(red: 0.90, green: 0.87, blue: 0.82, alpha: 1.0))
    let textSecondary = Color(nsColor: NSColor(red: 0.55, green: 0.52, blue: 0.47, alpha: 1.0))
    let textTertiary = Color(nsColor: NSColor(red: 0.38, green: 0.36, blue: 0.32, alpha: 1.0))
    let divider = Color(nsColor: NSColor(red: 0.22, green: 0.20, blue: 0.18, alpha: 1.0))
    let saved = Color(nsColor: NSColor(red: 0.40, green: 0.65, blue: 0.40, alpha: 1.0))
    let unsaved = Color(nsColor: NSColor(red: 0.80, green: 0.55, blue: 0.25, alpha: 1.0))
    let tabBarBackground = Color(nsColor: NSColor(red: 0.09, green: 0.08, blue: 0.07, alpha: 1.0))
    let tabActive = Color(nsColor: NSColor(red: 0.16, green: 0.15, blue: 0.13, alpha: 1.0))
    let tabHover = Color(nsColor: NSColor(red: 0.13, green: 0.12, blue: 0.10, alpha: 1.0))
    let tabCloseHover = Color(nsColor: NSColor(red: 0.25, green: 0.23, blue: 0.20, alpha: 1.0))
}

// MARK: - Parchment (warm light)

struct ParchmentTheme: ThemeColors {
    let name = "Parchment"
    let editorBackground = Color(nsColor: NSColor(red: 0.96, green: 0.93, blue: 0.88, alpha: 1.0))
    let chatBackground = Color(nsColor: NSColor(red: 0.94, green: 0.91, blue: 0.86, alpha: 1.0))
    let inputBackground = Color(nsColor: NSColor(red: 0.92, green: 0.89, blue: 0.84, alpha: 1.0))
    let userBubble = Color(nsColor: NSColor(red: 0.88, green: 0.85, blue: 0.80, alpha: 1.0))
    let assistantBubble = Color(nsColor: NSColor(red: 0.91, green: 0.88, blue: 0.83, alpha: 1.0))
    let accent = Color(nsColor: NSColor(red: 0.60, green: 0.35, blue: 0.15, alpha: 1.0))
    let textPrimary = Color(nsColor: NSColor(red: 0.15, green: 0.13, blue: 0.10, alpha: 1.0))
    let textSecondary = Color(nsColor: NSColor(red: 0.45, green: 0.40, blue: 0.35, alpha: 1.0))
    let textTertiary = Color(nsColor: NSColor(red: 0.62, green: 0.58, blue: 0.52, alpha: 1.0))
    let divider = Color(nsColor: NSColor(red: 0.82, green: 0.78, blue: 0.72, alpha: 1.0))
    let saved = Color(nsColor: NSColor(red: 0.30, green: 0.55, blue: 0.30, alpha: 1.0))
    let unsaved = Color(nsColor: NSColor(red: 0.75, green: 0.45, blue: 0.15, alpha: 1.0))
    let tabBarBackground = Color(nsColor: NSColor(red: 0.90, green: 0.87, blue: 0.82, alpha: 1.0))
    let tabActive = Color(nsColor: NSColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0))
    let tabHover = Color(nsColor: NSColor(red: 0.94, green: 0.91, blue: 0.86, alpha: 1.0))
    let tabCloseHover = Color(nsColor: NSColor(red: 0.82, green: 0.78, blue: 0.72, alpha: 1.0))
}

// MARK: - Midnight (cool dark)

struct MidnightTheme: ThemeColors {
    let name = "Midnight"
    let editorBackground = Color(nsColor: NSColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0))
    let chatBackground = Color(nsColor: NSColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 1.0))
    let inputBackground = Color(nsColor: NSColor(red: 0.14, green: 0.15, blue: 0.19, alpha: 1.0))
    let userBubble = Color(nsColor: NSColor(red: 0.16, green: 0.17, blue: 0.22, alpha: 1.0))
    let assistantBubble = Color(nsColor: NSColor(red: 0.12, green: 0.13, blue: 0.17, alpha: 1.0))
    let accent = Color(nsColor: NSColor(red: 0.40, green: 0.60, blue: 0.85, alpha: 1.0))
    let textPrimary = Color(nsColor: NSColor(red: 0.85, green: 0.87, blue: 0.92, alpha: 1.0))
    let textSecondary = Color(nsColor: NSColor(red: 0.48, green: 0.52, blue: 0.58, alpha: 1.0))
    let textTertiary = Color(nsColor: NSColor(red: 0.32, green: 0.35, blue: 0.40, alpha: 1.0))
    let divider = Color(nsColor: NSColor(red: 0.18, green: 0.19, blue: 0.24, alpha: 1.0))
    let saved = Color(nsColor: NSColor(red: 0.35, green: 0.60, blue: 0.45, alpha: 1.0))
    let unsaved = Color(nsColor: NSColor(red: 0.75, green: 0.50, blue: 0.30, alpha: 1.0))
    let tabBarBackground = Color(nsColor: NSColor(red: 0.06, green: 0.06, blue: 0.09, alpha: 1.0))
    let tabActive = Color(nsColor: NSColor(red: 0.12, green: 0.13, blue: 0.17, alpha: 1.0))
    let tabHover = Color(nsColor: NSColor(red: 0.09, green: 0.10, blue: 0.13, alpha: 1.0))
    let tabCloseHover = Color(nsColor: NSColor(red: 0.20, green: 0.22, blue: 0.28, alpha: 1.0))
}

// MARK: - Desert (warm earthy)

struct DesertTheme: ThemeColors {
    let name = "Desert"
    let editorBackground = Color(nsColor: NSColor(red: 0.16, green: 0.12, blue: 0.09, alpha: 1.0))
    let chatBackground = Color(nsColor: NSColor(red: 0.18, green: 0.14, blue: 0.11, alpha: 1.0))
    let inputBackground = Color(nsColor: NSColor(red: 0.22, green: 0.18, blue: 0.14, alpha: 1.0))
    let userBubble = Color(nsColor: NSColor(red: 0.25, green: 0.20, blue: 0.15, alpha: 1.0))
    let assistantBubble = Color(nsColor: NSColor(red: 0.20, green: 0.16, blue: 0.12, alpha: 1.0))
    let accent = Color(nsColor: NSColor(red: 0.82, green: 0.45, blue: 0.22, alpha: 1.0))
    let textPrimary = Color(nsColor: NSColor(red: 0.92, green: 0.85, blue: 0.75, alpha: 1.0))
    let textSecondary = Color(nsColor: NSColor(red: 0.58, green: 0.48, blue: 0.38, alpha: 1.0))
    let textTertiary = Color(nsColor: NSColor(red: 0.40, green: 0.32, blue: 0.25, alpha: 1.0))
    let divider = Color(nsColor: NSColor(red: 0.26, green: 0.21, blue: 0.16, alpha: 1.0))
    let saved = Color(nsColor: NSColor(red: 0.45, green: 0.60, blue: 0.35, alpha: 1.0))
    let unsaved = Color(nsColor: NSColor(red: 0.82, green: 0.50, blue: 0.20, alpha: 1.0))
    let tabBarBackground = Color(nsColor: NSColor(red: 0.11, green: 0.08, blue: 0.06, alpha: 1.0))
    let tabActive = Color(nsColor: NSColor(red: 0.20, green: 0.16, blue: 0.12, alpha: 1.0))
    let tabHover = Color(nsColor: NSColor(red: 0.15, green: 0.12, blue: 0.09, alpha: 1.0))
    let tabCloseHover = Color(nsColor: NSColor(red: 0.28, green: 0.22, blue: 0.18, alpha: 1.0))
}
