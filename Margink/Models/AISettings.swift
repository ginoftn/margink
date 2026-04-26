import Foundation

@MainActor @Observable
final class AISettings {
    static let shared = AISettings()

    var systemPrompt: String {
        didSet { UserDefaults.standard.set(systemPrompt, forKey: "margink.ai.systemPrompt") }
    }

    var maxTurns: Int {
        didSet { UserDefaults.standard.set(maxTurns, forKey: "margink.ai.maxTurns") }
    }

    var allowEdit: Bool {
        didSet { UserDefaults.standard.set(allowEdit, forKey: "margink.ai.allowEdit") }
    }

    var allowWrite: Bool {
        didSet { UserDefaults.standard.set(allowWrite, forKey: "margink.ai.allowWrite") }
    }

    var allowBash: Bool {
        didSet { UserDefaults.standard.set(allowBash, forKey: "margink.ai.allowBash") }
    }

    var disallowedTools: [String] {
        var tools: [String] = []
        if !allowEdit { tools.append("Edit") }
        if !allowWrite { tools.append("Write") }
        if !allowBash { tools.append("Bash") }
        return tools
    }

    static let defaultSystemPrompt = "You are a writing assistant integrated into Margink, a markdown editor. Help the user improve, reformulate, develop and rework their text. Be concise and direct."

    private init() {
        self.systemPrompt = UserDefaults.standard.string(forKey: "margink.ai.systemPrompt")
            ?? AISettings.defaultSystemPrompt
        self.maxTurns = UserDefaults.standard.object(forKey: "margink.ai.maxTurns") as? Int ?? 3
        self.allowEdit = UserDefaults.standard.object(forKey: "margink.ai.allowEdit") as? Bool ?? false
        self.allowWrite = UserDefaults.standard.object(forKey: "margink.ai.allowWrite") as? Bool ?? false
        self.allowBash = UserDefaults.standard.object(forKey: "margink.ai.allowBash") as? Bool ?? false
    }

    func resetToDefaults() {
        systemPrompt = AISettings.defaultSystemPrompt
        maxTurns = 3
        allowEdit = false
        allowWrite = false
        allowBash = false
    }
}
