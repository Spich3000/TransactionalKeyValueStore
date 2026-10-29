extension TransactionalStore {
    public static let keyNotSetMessage = "key not set"
    public static let noTransactionMessage = "no transaction"

    /// Runs a command and returns the text a console would print, if any.
    @discardableResult
    public mutating func execute(_ command: Command) -> String? {
        switch command {
        case let .set(key, value):
            setValue(value, forKey: key)
            return nil
        case let .get(key):
            return value(forKey: key) ?? Self.keyNotSetMessage
        case let .delete(key):
            return removeValue(forKey: key) == nil ? Self.keyNotSetMessage : nil
        case let .count(value):
            return String(count(of: value))
        case .begin:
            begin()
            return nil
        case .commit:
            do { try commit() } catch { return Self.noTransactionMessage }
            return nil
        case .rollback:
            do { try rollback() } catch { return Self.noTransactionMessage }
            return nil
        }
    }
}
