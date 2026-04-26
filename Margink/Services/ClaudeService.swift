import Foundation
import ClaudeCodeSDK
import os.log

private let logger = Logger(subsystem: "com.margink.app", category: "ClaudeService")

/// Wrapper around ClaudeCodeSDK for contextual AI chat in the editor.
@MainActor
@Observable
final class ClaudeService {

    private(set) var isLoading = false
    private let client: ClaudeCodeClient

    init() throws {
        var config = ClaudeCodeConfiguration.default
        config.additionalPaths.append(
            NSString("~/.local/bin").expandingTildeInPath
        )
        config.disallowedTools = ["Edit", "Write", "Bash"]
        // Prevent "nested session" error when launched from Claude Code
        config.environment["CLAUDECODE"] = ""

        do {
            self.client = try ClaudeCodeClient(configuration: config)
        } catch {
            logger.error("[Margink] ClaudeCodeClient init failed: \(String(describing: error))")
            throw error
        }
    }

    /// First message on a document. Sends the file content + user message.
    func sendFirst(
        fileContent: String,
        message: String
    ) async throws -> (response: String, sessionId: String?) {
        isLoading = true
        defer { isLoading = false }

        var options = ClaudeCodeOptions()
        options.systemPrompt = "You are a writing assistant integrated into Margink, a markdown editor. Help the user improve, reformulate, develop and rework their text. Be concise and direct."
        options.maxTurns = 3

        let prompt = """
        [Document content]

        \(fileContent)

        ---

        \(message)
        """

        let result = try await client.runSinglePrompt(
            prompt: prompt,
            outputFormat: .json,
            options: options
        )
        return extractResponse(from: result)
    }

    /// Follow-up message on an existing conversation.
    func sendFollowUp(
        sessionId: String,
        message: String,
        fileContent: String?,
        fileChanged: Bool
    ) async throws -> (response: String, sessionId: String?) {
        isLoading = true
        defer { isLoading = false }

        let prompt: String
        if fileChanged, let content = fileContent {
            prompt = """
            [Document updated]

            \(content)

            ---

            \(message)
            """
        } else {
            prompt = message
        }

        var options = ClaudeCodeOptions()
        options.maxTurns = 3

        let result = try await client.resumeConversation(
            sessionId: sessionId,
            prompt: prompt,
            outputFormat: .json,
            options: options
        )
        return extractResponse(from: result)
    }

    private func extractResponse(
        from result: ClaudeCodeResult
    ) -> (response: String, sessionId: String?) {
        switch result {
        case .text(let content):
            return (content, nil)
        case .json(let resultMessage):
            let text = resultMessage.result ?? "No response"
            return (text, resultMessage.sessionId)
        case .stream:
            return ("Unexpected streaming response", nil)
        }
    }
}
