import SwiftUI

struct OccurrenceItemRow: View {

    @Bindable var item: OccurrenceItem

    let isPast: Bool
    let isFuture: Bool

    var body: some View {

        HStack(spacing: 16) {

            Button {

                guard !isFuture else {
                    return
                }

                item.checked.toggle()

                if item.checked {
                    item.checkedAt = Date()
                } else {
                    item.checkedAt = nil
                }

            } label: {

                CheckmarkBox(
                    isChecked: item.checked
                )
                .opacity(
                    isFuture
                        ? 0.45
                        : 1.0
                )
            }
            .buttonStyle(.plain)
            .disabled(isFuture)

            Text(item.text)
                .font(.system(size: 17))
                .foregroundStyle(
                    isPast
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

            if let remindAt = item.remindAt {

                Text(
                    remindAt,
                    format: .dateTime
                        .hour()
                        .minute()
                )
                .font(.system(size: 15))
                .foregroundStyle(
                    isPast
                        ? Color.secondary.opacity(0.65)
                        : Color.secondary
                )
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
