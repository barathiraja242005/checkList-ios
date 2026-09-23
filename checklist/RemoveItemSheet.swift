import SwiftUI

struct RemoveItemSheet: View {

    let itemText: String

    // Drives the wording: what "just one" means depends on how often the
    // task comes back.
    var recurrence: Recurrence = .daily
    let onJustToday: () -> Void
    let onTodayAndFuture: () -> Void
    let onCancel: () -> Void

    private let accent = Color.accentGreen

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            // MARK: - Title

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text("Remove “\(itemText)”?")
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("Earlier days keep their record either way.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .padding(.bottom, 18)

            // MARK: - Options

            VStack(spacing: 0) {

                optionRow(
                    icon: "arrow.uturn.forward",
                    iconTint: accent,
                    title: recurrence.skipTitle,
                    subtitle: recurrence.skipSummary,
                    titleColor: .primary,
                    action: onJustToday
                )

                Divider()
                    .padding(.leading, 52)

                optionRow(
                    icon: "trash",
                    iconTint: .red,
                    title: recurrence.removeAllTitle,
                    subtitle: "Removes it from your routine.",
                    titleColor: .red,
                    action: onTodayAndFuture
                )
            }
            .background(Color(.systemGray6))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )

            // MARK: - Cancel

            Button {
                onCancel()
            } label: {

                Text("Cancel")
                    .font(
                        .system(
                            size: 15,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(.horizontal, 22)
        .padding(.top, 24)
        .padding(.bottom, 6)
    }

    // MARK: - Option Row

    private func optionRow(
        icon: String,
        iconTint: Color,
        title: String,
        subtitle: String,
        titleColor: Color,
        action: @escaping () -> Void
    ) -> some View {

        Button {
            action()
        } label: {

            HStack(spacing: 14) {

                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(iconTint)
                    .frame(width: 24)

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text(title)
                        .font(
                            .system(
                                size: 15,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(titleColor)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {

    Color.black.opacity(0.2)
        .sheet(isPresented: .constant(true)) {

            RemoveItemSheet(
                itemText: "Evening tablet",
                onJustToday: {},
                onTodayAndFuture: {},
                onCancel: {}
            )
            .presentationDetents([.height(290)])
            .presentationDragIndicator(.visible)
        }
}
