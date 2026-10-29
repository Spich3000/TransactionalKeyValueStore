import Testing
@testable import TransactionalStore

@Suite("Command parsing")
struct CommandParsingTests {
    @Test(arguments: [
        ("SET foo 123", Command.set(key: "foo", value: "123")),
        ("set foo 123", .set(key: "foo", value: "123")),
        ("  SET   foo   hello  world  ", .set(key: "foo", value: "hello  world")),
        ("GET foo", .get(key: "foo")),
        ("DELETE foo", .delete(key: "foo")),
        ("COUNT 123", .count(value: "123")),
        ("COUNT hello  world", .count(value: "hello  world")),
        ("BEGIN", .begin),
        ("commit", .commit),
        ("Rollback", .rollback),
    ])
    func parsesValidInput(input: String, expected: Command) throws {
        #expect(try Command(parsing: input) == expected)
    }

    @Test func keysAndValuesAreCaseSensitive() throws {
        #expect(try Command(parsing: "SET Foo Bar") == .set(key: "Foo", value: "Bar"))
    }

    @Test func rejectsEmptyInput() {
        #expect(throws: CommandParseError.empty) { try Command(parsing: "   ") }
    }

    @Test func rejectsUnknownCommands() {
        #expect(throws: CommandParseError.unknownCommand("PUT")) { try Command(parsing: "PUT foo 1") }
    }

    @Test(arguments: [
        ("SET", Command.Keyword.set),
        ("SET foo", .set),
        ("GET", .get),
        ("GET foo bar", .get),
        ("DELETE", .delete),
        ("COUNT", .count),
        ("BEGIN now", .begin),
        ("COMMIT 1", .commit),
        ("ROLLBACK x", .rollback),
    ])
    func rejectsWrongArguments(input: String, keyword: Command.Keyword) {
        #expect(throws: CommandParseError.invalidArguments(keyword)) { try Command(parsing: input) }
    }

    @Test func errorsDescribeUsage() {
        #expect(CommandParseError.invalidArguments(.set).description == "Usage: SET <key> <value>")
    }

    @Test func onlyDestructiveCommandsRequireConfirmation() {
        let confirmed = Command.Keyword.allCases.filter { keyword in
            let command: Command = switch keyword {
            case .set: .set(key: "k", value: "v")
            case .get: .get(key: "k")
            case .delete: .delete(key: "k")
            case .count: .count(value: "v")
            case .begin: .begin
            case .commit: .commit
            case .rollback: .rollback
            }
            return command.requiresConfirmation
        }
        #expect(confirmed == [.delete, .commit, .rollback])
    }
}
