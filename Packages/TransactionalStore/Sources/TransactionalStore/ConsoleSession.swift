import Observation

/// One submitted line together with what the store printed in response.
public struct ConsoleEntry: Identifiable, Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case output
        case error
        case cancelled
    }

    public let id: Int
    public let input: String
    public let output: String?
    public let kind: Kind

    public init(id: Int, input: String, output: String?, kind: Kind) {
        self.id = id
        self.input = input
        self.output = output
        self.kind = kind
    }
}

/// Drives an interactive session against a ``TransactionalStore``: parses input,
/// holds destructive commands until they are confirmed, and records history.
@MainActor
@Observable
public final class ConsoleSession {
    public private(set) var store: TransactionalStore
    public private(set) var history: [ConsoleEntry] = []

    /// A destructive command waiting for ``confirmPendingCommand()`` or ``cancelPendingCommand()``.
    public private(set) var pendingCommand: PendingCommand?

    public struct PendingCommand: Equatable, Sendable {
        public let input: String
        public let command: Command
    }

    @ObservationIgnored private var nextEntryID = 0

    public init(store: TransactionalStore = TransactionalStore()) {
        self.store = store
    }

    /// Submits one line of input. Returns `false` if nothing was submitted.
    @discardableResult
    public func submit(_ line: String) -> Bool {
        let input = String(line.trimmingWhitespace())
        guard !input.isEmpty, pendingCommand == nil else { return false }

        let command: Command
        do {
            command = try Command(parsing: input)
        } catch {
            record(input, output: error.description, kind: .error)
            return true
        }

        if command.requiresConfirmation {
            pendingCommand = PendingCommand(input: input, command: command)
        } else {
            run(command, input: input)
        }
        return true
    }

    public func confirmPendingCommand() {
        guard let pending = pendingCommand.take() else { return }
        run(pending.command, input: pending.input)
    }

    public func cancelPendingCommand() {
        guard let pending = pendingCommand.take() else { return }
        record(pending.input, output: "cancelled", kind: .cancelled)
    }

    public func clearHistory() {
        history.removeAll()
    }

    private func run(_ command: Command, input: String) {
        let output = store.execute(command)
        let failed = output == TransactionalStore.noTransactionMessage
        record(input, output: output, kind: failed ? .error : .output)
    }

    private func record(_ input: String, output: String?, kind: ConsoleEntry.Kind) {
        history.append(ConsoleEntry(id: nextEntryID, input: input, output: output, kind: kind))
        nextEntryID += 1
    }
}

private extension Optional {
    mutating func take() -> Wrapped? {
        defer { self = nil }
        return self
    }
}
