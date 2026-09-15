import SwiftUI
import SwiftData

struct TodayItemRow: View {

    @Bindable var item: TodayItem

    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var occurrences: [Occurrence]

    @State private var navigateToDetail = false
    @State private var showingRemoveSheet = false
    @State private var showingDeleteConfirmation = false

    @State private var isEditing = false

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {

        SwipeActionRow(
            content: {
                rowContent
            },
            onEdit: {
                isEditing = true

                DispatchQueue.main.async {
                    isTextFieldFocused = true
                }
            },
            onDelete: {
                handleDelete()
            }
        )
        .navigationDestination(
            isPresented: $navigateToDetail
        ) {
            ItemDetailView(
                item: item
            )
        }

        // MARK: - Daily Item Remove Sheet

        .sheet(
            isPresented: $showingRemoveSheet
        ) {
            RemoveItemSheet(
                itemText: item.text,
                onJustToday: {
                    TodayItemRemoval.removeJustToday(
                        item,
                        context: modelContext
                    )

                    showingRemoveSheet = false
                },
                onTodayAndFuture: {
                    TodayItemRemoval.removeTodayAndFuture(
                        item,
                        occurrences: occurrences,
                        context: modelContext
                    )

                    showingRemoveSheet = false
                },
                onCancel: {
                    showingRemoveSheet = false
                }
            )
            // 290 rather than 250 to fit the redesigned sheet's card layout.
            .presentationDetents([.height(290)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.white)
        }

        // MARK: - One-Time Item Delete Confirmation

        .alert(
            "Delete \(item.text)?",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                deleteOneTimeItem()
            }

            Button("Cancel", role: .cancel) {
                showingDeleteConfirmation = false
            }
        } message: {
            Text("This item will be permanently deleted.")
        }
    }

    // MARK: - Row Content

    private var rowContent: some View {

        HStack(spacing: 16) {

            // MARK: - Checkbox

            Button {
                item.checked.toggle()
                saveChanges()
            } label: {
                CheckmarkBox(
                    isChecked: item.checked
                )
            }
            .buttonStyle(.plain)

            // MARK: - Item Name

            if isEditing {

                TextField(
                    "Item name",
                    text: $item.text
                )
                .font(.system(size: 18))
                .focused($isTextFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    finishEditing()
                }

            } else {

                Button {
                    navigateToDetail = true
                } label: {
                    Text(item.text)
                        .font(
                            .system(size: 18)
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
                }
                .buttonStyle(.plain)
            }

            // MARK: - Time

            if let remindAt = item.remindAt {

                Text(
                    remindAt,
                    format: .dateTime
                        .hour()
                        .minute()
                )
                .font(
                    .system(size: 16)
                )
                .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 2)
        .frame(minHeight: 58)
    }

    // MARK: - Finish Editing

    private func finishEditing() {

        let trimmed = item.text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !trimmed.isEmpty {
            item.text = trimmed
        }

        isEditing = false
        isTextFieldFocused = false

        saveChanges()
    }

    // MARK: - Delete Handling

    private func handleDelete() {

        if item.repeatsDaily {

            showingRemoveSheet = true

        } else {

            showingDeleteConfirmation = true
        }
    }

    // MARK: - Delete One-Time Item

    private func deleteOneTimeItem() {

        if item.reminderEnabled {
            NotificationManager.cancelReminder(
                for: item
            )
        }

        modelContext.delete(item)

        do {
            try modelContext.save()
        } catch {
            print(
                "Failed to delete one-time item: \(error)"
            )
        }
    }

    // MARK: - Save

    private func saveChanges() {

        do {
            try modelContext.save()
        } catch {
            print(
                "Failed to save Today item change: \(error)"
            )
        }
    }
}
