import Foundation
import os.log

private let logger = Logger(subsystem: "com.margink.app", category: "FileWatcher")

/// Watches a file for external modifications using polling.
/// DispatchSource loses track after atomic writes (rename), so we poll instead.
@MainActor
final class FileWatcher {
    private var timer: DispatchSourceTimer?
    private var lastKnownModDate: Date?
    private var lastKnownContent: String?
    private let filePath: String
    private let onChange: () -> Void
    private var paused = false

    init(filePath: String, onChange: @escaping () -> Void) {
        self.filePath = filePath
        self.onChange = onChange
    }

    func start() {
        stop()

        lastKnownModDate = modificationDate()
        lastKnownContent = try? String(contentsOfFile: filePath, encoding: .utf8)

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 1, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            self?.check()
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    /// Pause watching temporarily (during our own writes).
    func pause() {
        paused = true
    }

    /// Resume watching and snapshot current state so we skip our own write.
    func resume() {
        lastKnownModDate = modificationDate()
        lastKnownContent = try? String(contentsOfFile: filePath, encoding: .utf8)
        paused = false
    }

    private func check() {
        guard !paused else { return }

        let currentMod = modificationDate()
        guard let current = currentMod else { return }
        guard let last = lastKnownModDate else {
            lastKnownModDate = current
            return
        }

        if current > last {
            let newContent = try? String(contentsOfFile: filePath, encoding: .utf8)
            if newContent != lastKnownContent {
                lastKnownModDate = current
                lastKnownContent = newContent
                logger.info("[FileWatcher] External change detected: \(self.filePath)")
                onChange()
            } else {
                lastKnownModDate = current
            }
        }
    }

    private func modificationDate() -> Date? {
        try? FileManager.default.attributesOfItem(atPath: filePath)[.modificationDate] as? Date
    }

    deinit {
        timer?.cancel()
    }
}
