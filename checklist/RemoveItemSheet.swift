import SwiftUI

struct RemoveItemSheet: View {

    let itemText: String

    let onJustToday: () -> Void
    let onTodayAndFuture: () -> Void
    let onCancel: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 42, height: 5)
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )
                .padding(.top, 12)
                .padding(.bottom, 18)

            Text("Remove \(itemText)")
                .font(
                    .system(
                        size: 21,
                        weight: .bold
                    )
                )

            Text(
                "Earlier days keep their record either way."
            )
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
            .padding(.top, 4)
            .padding(.bottom, 20)

            Button {

                onJustToday()

            } label: {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Just today")
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)

                    Text(
                        "Stays on your list from tomorrow. Use this when you're skipping a day."
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            Divider()

            Button {

                onTodayAndFuture()

            } label: {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Today and future days")
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)

                    Text(
                        "Removes it from your routine for good."
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {

                onCancel()

            } label: {

                Text("Cancel")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 10)
        .background(Color.white)
    }
}

// MARK: - Preview

#Preview {

    RemoveItemSheet(
        itemText: "Evening tablet",
        onJustToday: {},
        onTodayAndFuture: {},
        onCancel: {}
    )
}
