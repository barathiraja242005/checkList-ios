import SwiftUI

struct RemoveItemSheet: View {

    let itemText: String
    let onJustToday: () -> Void
    let onTodayAndFuture: () -> Void
    let onCancel: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            // MARK: - Title

            Text("Remove \(itemText)")
                .font(
                    .system(
                        size: 20,
                        weight: .semibold
                    )
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

            // MARK: - Just Today

            Button {
                onJustToday()
            } label: {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Just today")
                        .font(
                            .system(size: 16, weight: .bold)
                        )
                        .foregroundStyle(
                            .primary
                        )

                    Text(
                        "Stays on your list from tomorrow."
                    )
                    .font(
                        .system(size: 12)
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(
                    .horizontal,
                    14
                )
                .padding(
                    .vertical,
                    8
                )
            }
            .buttonStyle(.plain)

            // MARK: - Today and Future

            Button {
                onTodayAndFuture()
            } label: {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Today and future days")
                        .font(
                            .system(size: 16, weight: .bold)
                        )
                        .foregroundStyle(
                            .primary
                        )

                    Text(
                        "Removes it from your routine for good."
                    )
                    .font(
                        .system(size: 12
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(
                    .horizontal,
                    14
                )
                .padding(
                    .vertical,
                    8
                )
            }
            .buttonStyle(.plain)

            // MARK: - Cancel

            Button {
                onCancel()
            } label: {

                Text("Cancel")
                    .font(
                        .system(size: 16)
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )
                    .padding(
                        .vertical,
                        6
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(
            .horizontal,
            24
        )
        .padding(
            .vertical,
            12
        )
    }
}

#Preview {

    RemoveItemSheet(
        itemText: "Evening tablet",
        onJustToday: {},
        onTodayAndFuture: {},
        onCancel: {}
    )
}
