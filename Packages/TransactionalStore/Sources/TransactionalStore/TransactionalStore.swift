/// An in-memory key-value store with nested transactions.
///
/// Every operation, including `count(of:)`, runs in O(1). Instead of copying the
/// store on `begin()`, each open transaction keeps an undo log holding the value
/// every touched key had when the transaction first modified it. Rolling back
/// replays that log; committing folds it into the enclosing transaction.
public struct TransactionalStore: Sendable, Equatable {
    private var values: [String: String] = [:]
    private var valueCounts: [String: Int] = [:]
    /// One frame per open transaction, innermost last. `nil` means the key was absent.
    private var undoFrames: [[String: String?]] = []

    public init() {}

    /// Number of transactions currently open.
    public var transactionDepth: Int { undoFrames.count }

    public var isInTransaction: Bool { !undoFrames.isEmpty }

    /// Current key-value pairs as seen from inside the innermost transaction.
    public var entries: [String: String] { values }

    public func value(forKey key: String) -> String? {
        values[key]
    }

    /// Number of keys whose current value equals `value`.
    public func count(of value: String) -> Int {
        valueCounts[value, default: 0]
    }

    public mutating func setValue(_ value: String, forKey key: String) {
        write(value, forKey: key)
    }

    /// Removes the key and returns the value it held, if any.
    @discardableResult
    public mutating func removeValue(forKey key: String) -> String? {
        let removed = values[key]
        if removed != nil {
            write(nil, forKey: key)
        }
        return removed
    }

    public mutating func begin() {
        undoFrames.append([:])
    }

    /// Makes the innermost transaction's changes part of its parent, or permanent
    /// when it is the outermost one.
    public mutating func commit() throws(TransactionError) {
        guard let committed = undoFrames.popLast() else { throw .noTransaction }
        guard let parent = undoFrames.indices.last else { return }

        // The parent must restore what it saw before *it* touched a key, so its
        // own entries take precedence over the committed frame's.
        undoFrames[parent].merge(committed) { parentOriginal, _ in parentOriginal }
    }

    /// Discards every change made since the innermost `begin()`.
    public mutating func rollback() throws(TransactionError) {
        guard let frame = undoFrames.popLast() else { throw .noTransaction }
        for (key, original) in frame {
            apply(original, forKey: key)
        }
    }

    private mutating func write(_ newValue: String?, forKey key: String) {
        if let frame = undoFrames.indices.last, undoFrames[frame].index(forKey: key) == nil {
            undoFrames[frame].updateValue(values[key], forKey: key)
        }
        apply(newValue, forKey: key)
    }

    private mutating func apply(_ newValue: String?, forKey key: String) {
        let oldValue = newValue.map { values.updateValue($0, forKey: key) } ?? values.removeValue(forKey: key)
        guard oldValue != newValue else { return }

        if let oldValue {
            valueCounts[oldValue, default: 0] -= 1
            if valueCounts[oldValue] == 0 { valueCounts[oldValue] = nil }
        }
        if let newValue {
            valueCounts[newValue, default: 0] += 1
        }
    }
}

public enum TransactionError: Error, Equatable, Sendable {
    case noTransaction
}
