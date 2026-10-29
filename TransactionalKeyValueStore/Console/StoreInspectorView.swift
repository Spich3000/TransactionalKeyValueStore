import SwiftUI
import TransactionalStore

struct StoreInspectorView: View {
    let store: TransactionalStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Open Transactions", value: store.transactionDepth, format: .number)
                    LabeledContent("Keys", value: store.entries.count, format: .number)
                }

                Section("Entries") {
                    if store.entries.isEmpty {
                        Text("The store is empty.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.entries.sorted { $0.key < $1.key }, id: \.key) { key, value in
                            LabeledContent(key, value: value)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    var store = TransactionalStore()
    store.setValue("123", forKey: "foo")
    store.setValue("abc", forKey: "bar")
    store.begin()
    return StoreInspectorView(store: store)
}
