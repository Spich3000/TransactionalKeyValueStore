# Transactional Key-Value Store

An iOS console for an in-memory key-value store with nested transactions,
written in Swift and SwiftUI.

```
> SET foo 123
> SET bar 456
> BEGIN
> SET foo 456
> BEGIN
> COUNT 456
2
> ROLLBACK
> GET foo
456
> COMMIT
> GET foo
456
```

## Commands

| Command             | Effect                                                       |
| ------------------- | ------------------------------------------------------------ |
| `SET <key> <value>` | Stores a value. The value runs to the end of the line        |
| `GET <key>`         | Prints the value, or `key not set`                           |
| `DELETE <key>`      | Removes the key                                              |
| `COUNT <value>`     | Prints how many keys currently hold the value                |
| `BEGIN`             | Opens a transaction; transactions can be nested              |
| `COMMIT`            | Applies the innermost transaction to its parent              |
| `ROLLBACK`          | Discards changes made in the innermost transaction           |

Command names are case-insensitive; keys and values are not. `COMMIT` and
`ROLLBACK` print `no transaction` when none is open. `DELETE`, `COMMIT` and
`ROLLBACK` ask for confirmation before they run.

Committing an inner transaction merges its changes into the enclosing one, so a
later `ROLLBACK` of the outer transaction discards them as well. Only committing
the outermost transaction makes changes permanent.

## Implementation

The store lives in a Swift package, `Packages/TransactionalStore`, with no
dependency on UIKit or SwiftUI. The app target contains only views.

`TransactionalStore` is a value type. Rather than copying the whole dictionary
on `BEGIN`, each open transaction keeps an undo log with the original value of
every key it touched:

- `SET` and `DELETE` record the key's previous value the first time a
  transaction modifies it, then write through to the live dictionary.
- `ROLLBACK` replays the innermost log.
- `COMMIT` merges the innermost log into its parent, keeping the parent's
  entries where both exist, since those describe the state the parent must
  restore.

A second dictionary maintains how many keys hold each value. As a result every
command, including `COUNT` and `BEGIN`, runs in constant time regardless of store
size or nesting depth, and memory grows only with the number of keys actually
modified inside transactions.

`ConsoleSession` is an `@Observable` model that parses input, holds destructive
commands until they are confirmed, and keeps the history shown in the console.

```
Packages/TransactionalStore/
  Sources/TransactionalStore/
    TransactionalStore.swift            storage and transactions
    Command.swift                       command model and parser
    TransactionalStore+Command.swift    command execution and console output
    ConsoleSession.swift                observable session for the UI
  Tests/TransactionalStoreTests/
TransactionalKeyValueStore/
  App/                                  app entry point
  Console/                              SwiftUI views
```

## Building

Requires Xcode 16 or later; the app targets iOS 17.

Open `TransactionalKeyValueStore.xcodeproj` and run the `TransactionalKeyValueStore`
scheme. To build from the command line:

```bash
xcodebuild build \
  -project TransactionalKeyValueStore.xcodeproj \
  -scheme TransactionalKeyValueStore \
  -destination 'generic/platform=iOS Simulator'
```

## Testing

The store, parser and session are covered by Swift Testing suites, including
every scenario from the original specification. They run on macOS without a
simulator:

```bash
swift test --package-path Packages/TransactionalStore
```

The same tests run from Xcode with Product > Test.
