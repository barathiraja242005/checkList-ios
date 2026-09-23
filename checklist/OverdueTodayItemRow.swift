import SwiftUI
import SwiftData

// A one-off Today task whose day has passed. Laid out to match
// OverdueItemRow so both kinds of overdue work read the same, minus the
// list name, which a Today task does not have.
struct OverdueTodayItemRow: View {

    @Bindable var item: TodayItem

    let accent: Color

    @Environment(\.modelContext) private var modelContext

    @State private var navigateToDetail = false
    @State private var showingRemoveSheet = false

    @Query
    private var occurrences: [Occurrence]

    var body: some View {

        SwipeActionRow(
            content: {
                rowContent
            },
            onEdit: {
                navigateToDetail = true
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

        // A repeat that has fallen behind is still a repeat, so removing it
        // asks the same question it would on the day itself.
        .sheet(
            isPresented: $showingRemoveSheet
        ) {
            RemoveItemSheet(
                itemText: item.text,
                recurrence: item.recurrence,
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
            .presentationDetents([.height(290)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.appBackground)
        }
    }

    // MARK: - Row Content

    private var rowContent: some View {

        HStack(spacing: 16) {

            Button {
                toggleChecked()
            } label: {
                CheckmarkBox(
                    isChecked: item.checked
                )
            }
            .buttonStyle(.plain)

            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                Button {
                    navigateToDetail = true
                } label: {

                    Text(item.text)
                        .font(
                            .system(size: 17)
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

                HStack(spacing: 6) {

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
                            .system(size: 12)
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
                                    size: 14,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(Color.accentGreen)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .fill(
                    Color(.systemGray5)
                )
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Actions

    private func toggleChecked() {

        item.checked.toggle()

        if item.checked,
            item.reminderEnabled {

            NotificationManager.cancelReminder(for: item)
        }

        save()
    }

    private func handleDelete() {

        if item.recurrence != .none {

            showingRemoveSheet = true

        } else {

            deleteItem()
        }
    }

    private func deleteItem() {

        if item.reminderEnabled {

            NotificationManager.cancelReminder(for: item)
        }

        modelContext.delete(item)


        save()
    }

    private func save() {

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to save overdue task change: \(error)"
            )
        }
    }
}
