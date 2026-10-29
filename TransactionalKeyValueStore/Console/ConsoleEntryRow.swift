import SwiftUI
import TransactionalStore

struct ConsoleEntryRow: View {
    let entry: ConsoleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(">")
                    .foregroundStyle(.secondary)
                Text(entry.input)
            }
            if let output = entry.output {
                Text(output)
                    .foregroundStyle(outputStyle)
                    .italic(entry.kind == .cancelled)
            }
        }
        .font(.system(.body, design: .monospaced))
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var outputStyle: AnyShapeStyle {
        switch entry.kind {
        case .output: AnyShapeStyle(.tint)
        case .error: AnyShapeStyle(.red)
        case .cancelled: AnyShapeStyle(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ConsoleEntryRow(entry: .init(id: 0, input: "GET foo", output: "123", kind: .output))
        ConsoleEntryRow(entry: .init(id: 1, input: "COMMIT", output: "no transaction", kind: .error))
        ConsoleEntryRow(entry: .init(id: 2, input: "DELETE foo", output: "cancelled", kind: .cancelled))
    }
    .padding()
}
