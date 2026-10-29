public enum Command: Equatable, Sendable {
    case set(key: String, value: String)
    case get(key: String)
    case delete(key: String)
    case count(value: String)
    case begin
    case commit
    case rollback

    public enum Keyword: String, CaseIterable, Sendable {
        case set = "SET"
        case get = "GET"
        case delete = "DELETE"
        case count = "COUNT"
        case begin = "BEGIN"
        case commit = "COMMIT"
        case rollback = "ROLLBACK"

        public var usage: String {
            switch self {
            case .set: "SET <key> <value>"
            case .get: "GET <key>"
            case .delete: "DELETE <key>"
            case .count: "COUNT <value>"
            case .begin, .commit, .rollback: rawValue
            }
        }

        /// Whether the command can be run without arguments.
        public var takesArguments: Bool {
            switch self {
            case .set, .get, .delete, .count: true
            case .begin, .commit, .rollback: false
            }
        }
    }

    public var keyword: Keyword {
        switch self {
        case .set: .set
        case .get: .get
        case .delete: .delete
        case .count: .count
        case .begin: .begin
        case .commit: .commit
        case .rollback: .rollback
        }
    }

    /// Destructive commands that a UI should confirm before running.
    public var requiresConfirmation: Bool {
        switch self {
        case .delete, .commit, .rollback: true
        case .set, .get, .count, .begin: false
        }
    }
}

public enum CommandParseError: Error, Equatable, Sendable, CustomStringConvertible {
    case empty
    case unknownCommand(String)
    case invalidArguments(Command.Keyword)

    public var description: String {
        switch self {
        case .empty: "Enter a command"
        case .unknownCommand(let name): "Unknown command \"\(name)\""
        case .invalidArguments(let keyword): "Usage: \(keyword.usage)"
        }
    }
}

extension Command {
    /// Parses a single input line such as `SET foo 123`.
    ///
    /// Command names are case-insensitive; keys and values are not. Keys are single
    /// tokens, while values run to the end of the line, so `SET greeting hello world`
    /// stores `"hello world"`.
    public init(parsing line: String) throws(CommandParseError) {
        let (name, rest) = line.trimmingWhitespace().splitFirstToken()
        guard !name.isEmpty else { throw .empty }
        guard let keyword = Keyword(rawValue: name.uppercased()) else { throw .unknownCommand(String(name)) }

        let (firstArgument, remainder) = rest.splitFirstToken()
        let key = String(firstArgument)

        switch keyword {
        case .set where !key.isEmpty && !remainder.isEmpty:
            self = .set(key: key, value: String(remainder))
        case .get where !key.isEmpty && remainder.isEmpty:
            self = .get(key: key)
        case .delete where !key.isEmpty && remainder.isEmpty:
            self = .delete(key: key)
        case .count where !rest.isEmpty:
            self = .count(value: String(rest))
        case .begin where rest.isEmpty:
            self = .begin
        case .commit where rest.isEmpty:
            self = .commit
        case .rollback where rest.isEmpty:
            self = .rollback
        default:
            throw .invalidArguments(keyword)
        }
    }
}

extension StringProtocol where SubSequence == Substring {
    func trimmingWhitespace() -> Substring {
        let start = firstIndex { !$0.isWhitespace } ?? endIndex
        let end = lastIndex { !$0.isWhitespace }.map(index(after:)) ?? start
        return self[start..<end]
    }

    /// Splits off the first whitespace-delimited token; the remainder has leading
    /// whitespace removed but is otherwise untouched.
    func splitFirstToken() -> (token: Substring, remainder: Substring) {
        let tokenEnd = firstIndex(where: \.isWhitespace) ?? endIndex
        return (self[startIndex..<tokenEnd], self[tokenEnd...].trimmingWhitespace())
    }
}
