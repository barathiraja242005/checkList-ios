import SwiftUI

// Swipe actions where the label is pinned to the row edge and never moves:
// the colour fill grows inward from that edge and progressively uncovers it.
// Swipe left for DELETE, swipe right for EDIT. Only a full swipe triggers an
// action — there are no tappable buttons, and a short swipe springs back.
struct SwipeActionRow<Content: View>: View {

    @ViewBuilder let content: Content

    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var rowWidth: CGFloat = 0

    private var triggerThreshold: CGFloat {
        max(rowWidth * 0.55, 140)
    }

    private let deleteFill = Color(
        red: 0.70,
        green: 0.13,
        blue: 0.13
    )
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
                .background(Color.white)
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
        .gesture(dragGesture)
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
                        size: 15,
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

    private var dragGesture: some Gesture {

        DragGesture(minimumDistance: 20)
            .onChanged { value in

                // Horizontal-dominant drags only, so vertical drags still
                // reach the list for scrolling and reordering.
                guard abs(value.translation.width)
                        > abs(value.translation.height)
                else {
                    return
                }

                offset = min(
                    max(value.translation.width, -rowWidth),
                    rowWidth
                )
            }
            .onEnded { _ in

                let settled = offset

                guard abs(settled) >= triggerThreshold
                else {

                    withAnimation(.easeOut(duration: 0.2)) {
                        offset = 0
                    }
                    return
                }

                withAnimation(.easeOut(duration: 0.15)) {
                    offset =
                        settled < 0
                        ? -rowWidth
                        : rowWidth
                }

                if settled < 0 {
                    onDelete()
                } else {
                    onEdit()
                }

                offset = 0
            }
    }
}
