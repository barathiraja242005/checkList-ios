import SwiftUI

// Open / All as a segmented switch: one track, with the selected half
// carried on a thumb that slides between them rather than two chips lighting
// up independently.
struct TaskFilterToggle: View {

    @Binding var showsCompleted: Bool

    @Namespace private var thumb

    var body: some View {

        HStack(spacing: 0) {

            segment(
                title: "Open",
                isOn: !showsCompleted
            ) {
                showsCompleted = false
            }

            segment(
                title: "All",
                isOn: showsCompleted
            ) {
                showsCompleted = true
            }
        }
        .padding(3)
        .background {

            Capsule()
                .fill(Color.controlTrack)
        }
        // Sized to its own content, so the track is a switch rather than a
        // bar stretched across the page.
        .fixedSize()
    }

    private func segment(
        title: String,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button {

            guard !isOn
            else {
                return
            }

            withAnimation(
                .spring(
                    response: 0.3,
                    dampingFraction: 0.82
                )
            ) {
                action()
            }

        } label: {

            Text(title)
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    isOn
                        ? Color.white
                        : Color.secondary
                )
                .frame(minWidth: 58)
                .padding(.vertical, 7)
                .background {

                    if isOn {

                        Capsule()
                            .fill(Color.accentGreen)
                            // The thumb is one shape moving between the two
                            // halves, not two that fade in and out.
                            .matchedGeometryEffect(
                                id: "thumb",
                                in: thumb
                            )
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {

    struct Harness: View {

        @State private var showsCompleted = false

        var body: some View {

            TaskFilterToggle(
                showsCompleted: $showsCompleted
            )
            .padding()
            .pageBackground()
        }
    }

    return Harness()
}
