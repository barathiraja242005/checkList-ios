import SwiftUI

struct TodayItemRow: View {

    @Bindable var item: TodayItem

    var body: some View {

        HStack(spacing: 16) {

            // MARK: - Checkbox

            Button {

                item.checked.toggle()

            } label: {

                CheckmarkBox(
                    isChecked: item.checked
                )
            }
            .buttonStyle(.plain)

            // MARK: - Item Name

            NavigationLink {

                ItemDetailView(
                    item: item
                )

            } label: {

                Text(item.text)
                    .font(.system(size: 18))
                    .foregroundStyle(
                        item.checked
                            ? Color.secondary
                            : Color.primary
                    )
                    .strikethrough(
                        item.checked,
                        color: .secondary
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
            .buttonStyle(.plain)

            // MARK: - Time

            if let remindAt = item.remindAt {

                Text(
                    remindAt,
                    format: .dateTime
                        .hour()
                        .minute()
                )
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 58)
        .overlay(
            alignment: .bottom
        ) {

            Rectangle()
                .fill(
                    Color(.systemGray5)
                )
                .frame(height: 1)
        }
    }
}
