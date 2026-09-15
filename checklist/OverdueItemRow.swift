import SwiftUI
import SwiftData

// An overdue list item surfaced on the Today screen. It behaves like any
// other task row — tap to edit, swipe for EDIT/DELETE — while also showing
// which list it belongs to and how late it is.
struct OverdueItemRow: View {

    @Bindable var item: ChecklistListItem

    let accent: Color

    @Environment(\.modelContext) private var modelContext

    @State private var navigateToDetail = false
    @State private var showingDeleteConfirmation = false

    var body: some View {

        SwipeActionRow(
            content: {
                rowContent
            },
            onEdit: {
                navigateToDetail = true
            },
            onDelete: {
                showingDeleteConfirmation = true
            }
        )
        .navigationDestination(
            isPresented: $navigateToDetail
        ) {
            ChecklistListItemDetailView(
                item: item
            )
        }
        .alert(
            "Delete \(item.text)?",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                deleteItem()
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

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            HStack(spacing: 16) {

                Button {
                    toggleChecked()
                } label: {
                    checkbox
                }
                .buttonStyle(.plain)

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

            HStack(spacing: 6) {

                if let listTitle = item.list?.title {

                    Text(listTitle)
                        .font(
                            .system(size: 13)
                        )
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("·")
                        .font(
                            .system(size: 13)
                        )
                        .foregroundStyle(.secondary)
                }

                if let scheduledDate = item.scheduledDate {

                    Text(
                        "Due " +
                        scheduledDate.formatted(
                            .dateTime
                                .day()
                                .month(.abbreviated)
                                .year()
                        )
                    )
                    .font(
                        .system(size: 13)
                    )
                    .foregroundStyle(
                        accent.opacity(0.85)
                    )
                    .fixedSize()
                }

                Spacer(minLength: 6)

                Button {
                    navigateToDetail = true
                } label: {

                    Text("Reschedule")
                        .font(
                            .system(
                                size: 15,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            Color(
                                red: 0.25,
                                green: 0.48,
                                blue: 0.39
                            )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 38)
        }
        .padding(.vertical, 11)
        .overlay(
            Rectangle()
                .fill(
                    Color(.systemGray5)
                )
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var checkbox: some View {

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

                Image(systemName: "checkmark")
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

    // MARK: - Actions

    // This is the same object the list holds, so ticking it here marks it
    // done there too; only the list's cached counts need refreshing.
    private func toggleChecked() {

        item.checked.toggle()

        if item.checked,
            item.reminderEnabled {

            NotificationManager.cancelReminder(
                for: item
            )
        }

        item.list?.updateCounts()

        save()
    }

    private func deleteItem() {

        if item.reminderEnabled {

            NotificationManager.cancelReminder(
                for: item
            )
        }

        let list = item.list

        modelContext.delete(item)

        list?.updateCounts()

        showingDeleteConfirmation = false

        save()
    }

    private func save() {

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to save overdue item change: \(error)"
            )
        }
    }
}
