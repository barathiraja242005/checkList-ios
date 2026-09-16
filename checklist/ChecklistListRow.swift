import SwiftUI
import SwiftData

struct ChecklistListRow: View {

    let list: ChecklistList

    @Binding var navigationPath: NavigationPath

    @Environment(\.modelContext) private var modelContext

    @State private var showingDeleteConfirmation = false

    var body: some View {

        SwipeActionRow(
            content: {
                rowContent
            },
            onEdit: {
                navigationPath.append(
                    AppRoute.editList(list.id)
                )
            },
            onDelete: {
                showingDeleteConfirmation = true
            }
        )
        .alert(
            "Delete \(list.title)?",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                deleteList()
            }

            Button("Cancel", role: .cancel) {
                showingDeleteConfirmation = false
            }
        } message: {
            Text(
                list.totalCount == 1
                ? "This list and its 1 item will be permanently deleted."
                : "This list and its \(list.totalCount) items will be permanently deleted."
            )
        }
    }

    // MARK: - Row Content

    private var rowContent: some View {

        Button {
            navigationPath.append(
                AppRoute.listDetail(list.id)
            )
        } label: {

            HStack {

                Text(list.title)
                    .font(.system(size: 17))
                    .foregroundStyle(.primary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                Text(
                    "\(list.checkedCount)/\(list.totalCount)"
                )
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
            .frame(minHeight: 52)
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
        .buttonStyle(.plain)
    }

    // MARK: - Delete

    private func deleteList() {

        // The list's items cascade with it, but their reminders are held by
        // the notification centre and have to be cancelled explicitly.
        for item in list.items where item.reminderEnabled {

            NotificationManager.cancelReminder(for: item)
        }

        modelContext.delete(list)

        showingDeleteConfirmation = false

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to delete list: \(error)"
            )
        }
    }
}
