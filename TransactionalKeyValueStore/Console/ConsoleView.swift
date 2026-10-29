import SwiftUI
import TransactionalStore

struct ConsoleView: View {
    @State private var session = ConsoleSession()
    @State private var input = ""
    @State private var isInspectorPresented = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            history
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    CommandInputBar(
                        text: $input,
                        isFocused: $isInputFocused,
                        isEnabled: session.pendingCommand == nil,
                        onSubmit: submit,
                        onRun: { session.submit($0.rawValue) }
                    )
                }
                .navigationTitle("Key-Value Store")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                .sheet(isPresented: $isInspectorPresented) {
                    StoreInspectorView(store: session.store)
                        .presentationDetents([.medium, .large])
                }
                .confirmationDialog(
                    session.pendingCommand.map(confirmationTitle) ?? "",
                    isPresented: isConfirmationPresented,
                    titleVisibility: .visible,
                    presenting: session.pendingCommand
                ) { pending in
                    Button(confirmationAction(for: pending.command), role: .destructive) {
                        session.confirmPendingCommand()
                    }
                    Button("Cancel", role: .cancel) {
                        session.cancelPendingCommand()
                    }
                }
        }
        .onAppear { isInputFocused = true }
    }

    private var history: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(session.history) { entry in
                        ConsoleEntryRow(entry: entry)
                            .id(entry.id)
                    }
                }
                .padding()
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                if session.history.isEmpty {
                    ContentUnavailableView(
                        "No Commands Yet",
                        systemImage: "terminal",
                        description: Text("Type a command such as SET foo 123, or pick one below.")
                    )
                }
            }
            .onChange(of: session.history.last?.id) { _, lastID in
                guard let lastID else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            TransactionDepthBadge(depth: session.store.transactionDepth)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Inspect Store", systemImage: "tablecells") {
                isInspectorPresented = true
            }
            Button("Clear History", systemImage: "trash") {
                session.clearHistory()
            }
            .disabled(session.history.isEmpty)
        }
    }

    /// Dismissing the dialog without choosing an option (for example by tapping
    /// outside it on iPad) must not leave the console locked. The binding is
    /// cleared before button actions run, so the cancel is deferred: after a
    /// confirm there is nothing left to cancel and the call is a no-op.
    private var isConfirmationPresented: Binding<Bool> {
        Binding(
            get: { session.pendingCommand != nil },
            set: { isPresented in
                guard !isPresented else { return }
                Task { @MainActor in session.cancelPendingCommand() }
            }
        )
    }

    private func submit() {
        if session.submit(input) {
            input = ""
        }
        isInputFocused = true
    }

    private func confirmationTitle(for pending: ConsoleSession.PendingCommand) -> String {
        switch pending.command {
        case .delete(let key): "Delete \u{201C}\(key)\u{201D}?"
        case .commit: "Commit the current transaction?"
        case .rollback: "Discard changes in the current transaction?"
        default: pending.input
        }
    }

    private func confirmationAction(for command: Command) -> String {
        switch command {
        case .delete: "Delete"
        case .commit: "Commit"
        case .rollback: "Roll Back"
        default: "Run"
        }
    }
}

#Preview {
    ConsoleView()
}
