import SwiftUI

/// Shows how many transactions are open; hidden when there are none.
struct TransactionDepthBadge: View {
    let depth: Int

    var body: some View {
        if depth > 0 {
            // Not a Label: toolbars render labels icon-only regardless of label style.
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.branch")
                Text(depth, format: .number)
                    .monospacedDigit()
            }
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .fixedSize()
            .foregroundStyle(.orange)
            .background(.orange.opacity(0.15), in: .capsule)
            .accessibilityLabel(Text("Open transactions: \(depth)"))
            .contentTransition(.numericText())
            .animation(.default, value: depth)
        }
    }
}
