import SwiftUI

// MARK: - FlowLayout
/// Layout personnalisé pour arranger les éléments en flux horizontal avec retour à la ligne
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var verticalSpacing: CGFloat?

    var effectiveVerticalSpacing: CGFloat {
        verticalSpacing ?? spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            subviews: subviews,
            horizontalSpacing: spacing,
            verticalSpacing: effectiveVerticalSpacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            horizontalSpacing: spacing,
            verticalSpacing: effectiveVerticalSpacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + verticalSpacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + horizontalSpacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    FlowLayout(spacing: 8) {
        ForEach(0..<10) { index in
            Text("Item \(index)")
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .clipShape(Capsule())
        }
    }
    .padding()
}
