import Testing
@testable import TransactionalStore

/// Replays the scenarios from the original task statement line by line,
/// confirming every destructive command.
@MainActor
@Suite("Console scenarios")
struct ConsoleScenarioTests {
    private func run(_ script: String) -> [String] {
        let session = ConsoleSession()
        for line in script.split(separator: "\n") {
            session.submit(String(line))
            session.confirmPendingCommand()
        }
        return session.history.compactMap(\.output)
    }

    @Test func setAndGet() {
        #expect(run("SET foo 123\nGET foo") == ["123"])
    }

    @Test func deleteValue() {
        #expect(run("SET foo 123\nDELETE foo\nGET foo") == ["key not set"])
    }

    @Test func countOccurrences() {
        #expect(run("SET foo 123\nSET bar 456\nSET baz 123\nCOUNT 123\nCOUNT 456") == ["2", "1"])
    }

    @Test func commitTransaction() {
        let output = run("""
            SET bar 123
            GET bar
            BEGIN
            SET foo 456
            GET bar
            DELETE bar
            COMMIT
            GET bar
            ROLLBACK
            GET foo
            """)
        #expect(output == ["123", "123", "key not set", "no transaction", "456"])
    }

    @Test func rollbackTransaction() {
        let output = run("""
            SET foo 123
            SET bar abc
            BEGIN
            SET foo 456
            GET foo
            SET bar def
            GET bar
            ROLLBACK
            GET foo
            GET bar
            COMMIT
            """)
        #expect(output == ["456", "def", "123", "abc", "no transaction"])
    }

    @Test func nestedTransactions() {
        let output = run("""
            SET foo 123
            SET bar 456
            BEGIN
            SET foo 456
            BEGIN
            COUNT 456
            GET foo
            SET foo 789
            GET foo
            ROLLBACK
            GET foo
            DELETE foo
            GET foo
            ROLLBACK
            GET foo
            """)
        #expect(output == ["2", "456", "789", "456", "key not set", "123"])
    }
}

@MainActor
@Suite("ConsoleSession")
struct ConsoleSessionTests {
    @Test func destructiveCommandsWaitForConfirmation() {
        let session = ConsoleSession()
        session.submit("SET foo 1")
        session.submit("DELETE foo")

        #expect(session.pendingCommand?.command == .delete(key: "foo"))
        #expect(session.store.value(forKey: "foo") == "1")

        session.confirmPendingCommand()
        #expect(session.pendingCommand == nil)
        #expect(session.store.value(forKey: "foo") == nil)
    }

    @Test func cancellingLeavesStoreUntouched() {
        let session = ConsoleSession()
        session.submit("SET foo 1")
        session.submit("DELETE foo")
        session.cancelPendingCommand()

        #expect(session.store.value(forKey: "foo") == "1")
        #expect(session.history.last?.kind == .cancelled)
    }

    @Test func inputIsIgnoredWhileConfirmationIsPending() {
        let session = ConsoleSession()
        session.submit("BEGIN")
        session.submit("ROLLBACK")

        #expect(session.submit("SET foo 1") == false)
        #expect(session.history.count == 1)
    }

    @Test func parseErrorsAreRecorded() {
        let session = ConsoleSession()
        session.submit("FETCH foo")

        #expect(session.history == [ConsoleEntry(id: 0, input: "FETCH foo", output: "Unknown command \"FETCH\"", kind: .error)])
    }

    @Test func blankInputIsIgnored() {
        let session = ConsoleSession()

        #expect(session.submit("   ") == false)
        #expect(session.history.isEmpty)
    }

    @Test func transactionErrorsAreMarkedAsErrors() {
        let session = ConsoleSession()
        session.submit("COMMIT")
        session.confirmPendingCommand()

        #expect(session.history.last?.kind == .error)
        #expect(session.history.last?.output == "no transaction")
    }
}
