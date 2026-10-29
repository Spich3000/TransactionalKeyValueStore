import SwiftUI
import TransactionalStore

struct CommandInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let isEnabled: Bool
    let onSubmit: () -> Void
    /// Runs a command that takes no arguments without touching the text field.
    let onRun: (Command.Keyword) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Command.Keyword.allCases, id: \.self) { keyword in
                        Button(keyword.rawValue) { pick(keyword) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .font(.system(.footnote, design: .monospaced).weight(.medium))
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)

            HStack(spacing: 8) {
                Text(">")
                    .foregroundStyle(.secondary)
                // A single-line field resigns first responder on Return, which hides
                // the keyboard after every command. A vertical field keeps focus, so
                // Return is handled here by stripping the newline and submitting.
                TextField("Command", text: $text, prompt: Text("SET key value"), axis: .vertical)
                    .lineLimit(1...4)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .focused(isFocused)
                    .onChange(of: text) { _, newValue in
                        guard newValue.contains(where: \.isNewline) else { return }
                        text = newValue.filter { !$0.isNewline }
                        onSubmit()
                    }
                Button("Run", systemImage: "arrow.up.circle.fill", action: onSubmit)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .disabled(isBlank)
            }
            .font(.system(.body, design: .monospaced))
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .background(.fill.tertiary, in: .rect(cornerRadius: 12))
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(.bar)
        .disabled(!isEnabled)
    }

    private var isBlank: Bool {
        text.allSatisfy(\.isWhitespace)
    }

    /// Commands with arguments are inserted for completion; the others run at once.
    private func pick(_ keyword: Command.Keyword) {
        if keyword.takesArguments {
            text = keyword.rawValue + " "
            isFocused.wrappedValue = true
        } else {
            onRun(keyword)
        }
    }
}
