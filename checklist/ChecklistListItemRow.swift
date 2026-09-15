import SwiftUI
import SwiftData

struct ChecklistListItemRow: View {

    @Bindable var item: ChecklistListItem
    let list: ChecklistList

    @Environment(\.modelContext) private var modelContext

    @State private var isEditing = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {

        SwipeActionRow(
            content: { rowContent },
            onEdit: {
                isEditing = true
                isTextFieldFocused = true
            },
            onDelete: {
                removeItem()
            }
        )
    }

    private var rowContent: some View {

        HStack(spacing: 12) {

            Button {

                toggleItem()

            } label: {

                RoundedRectangle(
                    cornerRadius: 5,
                    style: .continuous
                )
                .stroke(
                    item.checked
                        ? Color.clear
                        : Color(.systemGray3),
                    lineWidth: 1.5
                )
                .background {

                    RoundedRectangle(
                        cornerRadius: 5,
                        style: .continuous
                    )
                    .fill(
                        item.checked
                            ? Color(
                                red: 0.18,
                                green: 0.48,
                                blue: 0.36
                            )
                            : Color.clear
                    )
                }
                .overlay {

                    if item.checked {

                        Image(
                            systemName: "checkmark"
                        )
                        .font(
                            .system(
                                size: 11,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                    }
                }
                .frame(
                    width: 22,
                    height: 22
                )
            }
            .buttonStyle(.plain)

            if isEditing {

                TextField(
                    "Item name",
                    text: $item.text
                )
                .font(.system(size: 16))
                .focused($isTextFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    commitEdit()
                }

            } else {

                Text(item.text)
                    .font(
                        .system(size: 16)
                    )
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
                    .contentShape(Rectangle())
                    .onTapGesture {

                        isEditing = true
                        isTextFieldFocused = true
                    }
            }

            Spacer()
        }
        .padding(.leading, 2)
        .frame(minHeight: 46)
    }

    private func toggleItem() {

        item.checked.toggle()

        list.updateCounts()

        save()
    }

    private func commitEdit() {

        let trimmed =
            item.text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        item.text =
            trimmed.isEmpty
            ? item.text
            : trimmed

        isEditing = false

        save()
    }

    private func removeItem() {

        modelContext.delete(item)

        list.updateCounts()

        save()
    }

    private func save() {

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to save list item change: \(error)"
            )
        }
    }
}
