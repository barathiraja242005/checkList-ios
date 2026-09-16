import SwiftUI

// Swipe actions where the label is pinned to the row edge and never moves:
// the colour fill grows inward from that edge and progressively uncovers it.
// Swipe left for DELETE, swipe right for EDIT. Only a full swipe triggers an
// action — there are no tappable buttons, and a short swipe springs back.
struct SwipeActionRow<Content: View>: View {

    @ViewBuilder let content: Content

    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.pageBackground) private var pageBackground

    @State private var offset: CGFloat = 0
    @State private var rowWidth: CGFloat = 0

    // Latched for the life of one gesture so a wobble cannot stall the row.
    @State private var isHorizontalDrag: Bool?

    private let activationDistance: CGFloat = 12

    private var triggerThreshold: CGFloat {
        max(rowWidth * 0.55, 140)
    }

    private let deleteFill = Color.deleteRed
        .opacity(0.85)

    private let editFill = Color(.systemGray)
        .opacity(0.72)

    // Breathing room between the row's own content and the colour fill. It
    // ramps in with the swipe rather than applying all at once, so the row
    // doesn't visibly jump the moment the gesture starts.
    private let contentGap: CGFloat = 16

    private var contentOffset: CGFloat {

        let gap = min(abs(offset), contentGap)

        return offset < 0
            ? offset - gap
            : offset + gap
    }

    var body: some View {

        ZStack {

            revealLayer(
                title: "EDIT",
                fill: editFill,
                edge: .leading,
                width: max(offset, 0)
            )

            revealLayer(
                title: "DELETE",
                fill: deleteFill,
                edge: .trailing,
                width: max(-offset, 0)
            )

            content
                .background(pageBackground)
                .offset(x: contentOffset)
        }
        .background {

            GeometryReader { proxy in

                Color.clear
                    .onAppear {
                        rowWidth = proxy.size.width
                    }
                    .onChange(of: proxy.size.width) { _, newWidth in
                        rowWidth = newWidth
                    }
            }
        }
        // List installs its own pan recognisers on every row, and both
        // .gesture() and .simultaneousGesture() lose that arbitration, so the
        // swipe never fires. High priority is what actually claims the drag.
        .highPriorityGesture(dragGesture)
    }

    // The label sits at a fixed offset from its edge; clipping the container
    // to `width` is what wipes it into view. The explicit frame alignment
    // matters — without it the oversized stack gets re-centred as the width
    // changes, which visibly drags the label sideways.
    private func revealLayer(
        title: String,
        fill: Color,
        edge: HorizontalAlignment,
        width: CGFloat
    ) -> some View {

        let alignment: Alignment =
            edge == .leading
            ? .leading
            : .trailing

        return ZStack(alignment: alignment) {

            fill

            Text(title)
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)
                .fixedSize()
                .padding(
                    edge == .leading
                        ? .leading
                        : .trailing,
                    24
                )
        }
        .frame(
            width: width,
            alignment: alignment
        )
        .clipped()
        .frame(
            maxWidth: .infinity,
            alignment: alignment
        )
    }

    // Travel past this point meets resistance, so the row feels like it is
    // being pulled rather than sliding freely to the edge.
    private func resistedOffset(
        for translation: CGFloat
    ) -> CGFloat {

        let direction: CGFloat =
            translation < 0 ? -1 : 1

        // Subtracting the activation distance means the row starts moving
        // from rest instead of jumping by that amount the moment the
        // gesture is recognised.
        let travelled = max(
            abs(translation) - activationDistance,
            0
        )

        let eased =
            travelled <= triggerThreshold
            ? travelled
            : triggerThreshold
                + (travelled - triggerThreshold) * 0.35

        return direction * min(eased, rowWidth)
    }

    private var dragGesture: some Gesture {

        DragGesture(
            minimumDistance: activationDistance
        )
        .onChanged { value in

            // The axis is decided once per gesture. Re-testing it on every
            // update made the row stall whenever a drag wobbled vertically.
            if isHorizontalDrag == nil {

                isHorizontalDrag =
                    abs(value.translation.width)
                        > abs(value.translation.height)
            }

            guard isHorizontalDrag == true
            else {
                return
            }

            offset = resistedOffset(
                for: value.translation.width
            )
        }
        .onEnded { _ in

            let wasHorizontal = isHorizontalDrag == true
            isHorizontalDrag = nil

            guard wasHorizontal
            else {
                return
            }

            let settled = offset

            // Settling back to rest in one spring, rather than animating out
            // to the edge and then snapping to zero, which fought itself.
            withAnimation(
                .interactiveSpring(
                    response: 0.34,
                    dampingFraction: 0.82
                )
            ) {
                offset = 0
            }

            guard abs(settled) >= triggerThreshold
            else {
                return
            }

            if settled < 0 {
                onDelete()
            } else {
                onEdit()
            }
            }
    }
}
