import SwiftUI

// Open / All switch for a task list. Same chip shape as the composer's time
// and repeat chips, so it reads as part of the same family.
struct TaskFilterChips: View {

    @Binding var showsCompleted: Bool

    var body: some View {

        HStack(spacing: 10) {

            chip(
                title: "Open",
                isOn: !showsCompleted
            ) {
                showsCompleted = false
            }

            chip(
                title: "All",
                isOn: showsCompleted
            ) {
                showsCompleted = true
            }

            Spacer()
        }
    }

    private func chip(
        title: String,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            Text(title)
                .font(
                    .system(size: 15)
                )
                .foregroundStyle(
                    isOn
                        ? Color.accentGreen
                        : Color.secondary
                )
                .padding(
                    .horizontal,
                    16
                )
                .padding(
                    .vertical,
                    8
                )
                .background {

                    Capsule()
                        .fill(
                            isOn
                                ? Color.accentSoft
                                : Color(.systemGray6)
                        )
                }
        }
        .buttonStyle(.plain)
    }
}
