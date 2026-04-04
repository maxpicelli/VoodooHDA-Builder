import Foundation

struct ShellCommandResult {
    let command: String
    let exitCode: Int32
    let output: String
}

enum ShellCommandError: LocalizedError {
    case failed(ShellCommandResult)

    var errorDescription: String? {
        switch self {
        case .failed(let result):
            return "Command failed with exit code \(result.exitCode): \(result.command)\n\(result.output)"
        }
    }
}

final class ShellCommandRunner {
    func run(
        _ command: String,
        in workingDirectory: String,
        environment: [String: String] = [:],
        onOutput: @escaping @MainActor (String) -> Void
    ) async throws -> ShellCommandResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()
            let outputQueue = DispatchQueue(label: "VoodooBuilderApp.ShellOutput")
            var buffer = Data()
            let cwdURL = URL(fileURLWithPath: workingDirectory, isDirectory: true)

            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lc", command]
            process.currentDirectoryURL = cwdURL
            process.standardOutput = stdout
            process.standardError = stderr

            var mergedEnvironment = ProcessInfo.processInfo.environment
            environment.forEach { mergedEnvironment[$0.key] = $0.value }
            process.environment = mergedEnvironment

            let appendData: (Data) -> Void = { data in
                guard !data.isEmpty else { return }
                outputQueue.async {
                    buffer.append(data)
                    if let chunk = String(data: data, encoding: .utf8), !chunk.isEmpty {
                        Task { @MainActor in
                            onOutput(chunk)
                        }
                    }
                }
            }

            stdout.fileHandleForReading.readabilityHandler = { handle in
                appendData(handle.availableData)
            }

            stderr.fileHandleForReading.readabilityHandler = { handle in
                appendData(handle.availableData)
            }

            process.terminationHandler = { process in
                stdout.fileHandleForReading.readabilityHandler = nil
                stderr.fileHandleForReading.readabilityHandler = nil

                outputQueue.async {
                    let result = ShellCommandResult(
                        command: command,
                        exitCode: process.terminationStatus,
                        output: String(data: buffer, encoding: .utf8) ?? ""
                    )

                    if process.terminationStatus == 0 {
                        continuation.resume(returning: result)
                    } else {
                        continuation.resume(throwing: ShellCommandError.failed(result))
                    }
                }
            }

            do {
                try process.run()
            } catch {
                stdout.fileHandleForReading.readabilityHandler = nil
                stderr.fileHandleForReading.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}