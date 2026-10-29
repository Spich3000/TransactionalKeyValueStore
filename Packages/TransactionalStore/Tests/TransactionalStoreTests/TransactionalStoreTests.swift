import Testing
@testable import TransactionalStore

@Suite("TransactionalStore")
struct TransactionalStoreTests {
    @Test func setAndGet() {
        var store = TransactionalStore()
        store.setValue("123", forKey: "foo")

        #expect(store.value(forKey: "foo") == "123")
        #expect(store.value(forKey: "bar") == nil)
    }

    @Test func overwriteUpdatesCounts() {
        var store = TransactionalStore()
        store.setValue("123", forKey: "foo")
        store.setValue("456", forKey: "foo")

        #expect(store.count(of: "123") == 0)
        #expect(store.count(of: "456") == 1)
    }

    @Test func removeReturnsPreviousValue() {
        var store = TransactionalStore()
        store.setValue("123", forKey: "foo")

        #expect(store.removeValue(forKey: "foo") == "123")
        #expect(store.removeValue(forKey: "foo") == nil)
        #expect(store.count(of: "123") == 0)
    }

    @Test func countOccurrences() {
        var store = TransactionalStore()
        store.setValue("123", forKey: "foo")
        store.setValue("456", forKey: "bar")
        store.setValue("123", forKey: "baz")

        #expect(store.count(of: "123") == 2)
        #expect(store.count(of: "456") == 1)
        #expect(store.count(of: "789") == 0)
    }

    @Test func commitAndRollbackWithoutTransactionFail() {
        var store = TransactionalStore()

        #expect(throws: TransactionError.noTransaction) { try store.commit() }
        #expect(throws: TransactionError.noTransaction) { try store.rollback() }
    }

    @Test func rollbackRestoresSetsAndDeletes() throws {
        var store = TransactionalStore()
        store.setValue("123", forKey: "foo")
        store.setValue("abc", forKey: "bar")

        store.begin()
        store.setValue("456", forKey: "foo")
        store.removeValue(forKey: "bar")
        store.setValue("new", forKey: "baz")
        try store.rollback()

        #expect(store.entries == ["foo": "123", "bar": "abc"])
        #expect(store.count(of: "123") == 1)
        #expect(store.count(of: "456") == 0)
        #expect(store.count(of: "new") == 0)
        #expect(!store.isInTransaction)
    }

    @Test func rollbackRestoresFirstValueAfterRepeatedWrites() throws {
        var store = TransactionalStore()
        store.setValue("1", forKey: "foo")

        store.begin()
        store.setValue("2", forKey: "foo")
        store.setValue("3", forKey: "foo")
        store.removeValue(forKey: "foo")
        try store.rollback()

        #expect(store.value(forKey: "foo") == "1")
    }

    @Test func commitKeepsChanges() throws {
        var store = TransactionalStore()
        store.setValue("123", forKey: "bar")

        store.begin()
        store.setValue("456", forKey: "foo")
        store.removeValue(forKey: "bar")
        try store.commit()

        #expect(store.entries == ["foo": "456"])
        #expect(throws: TransactionError.noTransaction) { try store.rollback() }
    }

    @Test func nestedRollbackOnlyUndoesInnermost() throws {
        var store = TransactionalStore()
        store.setValue("123", forKey: "foo")
        store.setValue("456", forKey: "bar")

        store.begin()
        store.setValue("456", forKey: "foo")
        store.begin()
        #expect(store.count(of: "456") == 2)
        store.setValue("789", forKey: "foo")
        try store.rollback()

        #expect(store.value(forKey: "foo") == "456")
        store.removeValue(forKey: "foo")
        try store.rollback()

        #expect(store.value(forKey: "foo") == "123")
        #expect(store.transactionDepth == 0)
    }

    @Test func committedInnerChangesAreRolledBackWithOuter() throws {
        var store = TransactionalStore()
        store.setValue("original", forKey: "foo")

        store.begin()
        store.setValue("outer", forKey: "foo")
        store.begin()
        store.setValue("inner", forKey: "foo")
        store.setValue("added", forKey: "bar")
        try store.commit()

        #expect(store.entries == ["foo": "inner", "bar": "added"])
        #expect(store.transactionDepth == 1)

        try store.rollback()
        #expect(store.entries == ["foo": "original"])
        #expect(store.count(of: "inner") == 0)
        #expect(store.count(of: "added") == 0)
    }

    @Test func deletingMissingKeyInsideTransactionLeavesNoTrace() throws {
        var store = TransactionalStore()
        store.begin()
        store.removeValue(forKey: "ghost")
        try store.rollback()

        #expect(store.entries.isEmpty)
    }
}
