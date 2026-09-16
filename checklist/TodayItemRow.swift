import SwiftUI
import SwiftData

struct TodayItemRow: View {

    @Bindable var item: TodayItem

    // Today's own list has no use for a date on every row — they are all
    // today. The Tasks tab mixes days together, so it asks for them.
    var showsDate: Bool = false

    // In the Tasks tab a repeat stands for its next open day rather than for
    // today, so its box starts empty and ticking it closes that day and moves
    // the row on to the one after.
    var tracksNextDue: Bool = false

    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var occurrences: [Occurrence]

    @State private var navigateToDetail = false
    @State private var showingRemoveSheet = false


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
            .presentationBackground(Color.appBackground)
        }

    }

    // MARK: - Row Content

    private var rowContent: some View {

        HStack(spacing: 16) {

            // MARK: - Checkbox

            Button {
                toggleCompletion()
            } label: {
                CheckmarkBox(
                    isChecked: displaysChecked
                )
            }
            .buttonStyle(.plain)

            // MARK: - Item Name

            Button {
                navigateToDetail = true
            } label: {

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text(item.text)
                        .font(
                            .system(size: 17)
                        )
                        .foregroundStyle(
                            displaysChecked
                                ? Color.secondary
                                : Color.primary
                        )
                        .strikethrough(
                            displaysChecked,
                            color: .secondary
                        )

                    if showsDate {

                        Text(dateLabel)
                            .font(
                                .system(size: 11)
                            )
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
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
                .font(
                    .system(size: 15)
                )
                .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 2)
        // Vertical padding stays inside the 58pt minimum for a single-line
        // title, so only wrapped titles actually grow the row.
        .padding(.vertical, 7)
        .frame(minHeight: 46)
    }

    // MARK: - Completion

    // A repeat in next-due mode is never shown as done: the day on the row is
    // by definition the first one still open.
    private var displaysChecked: Bool {

        tracksNextDue && item.repeatsDaily
            ? false
            : item.checked
    }

    private func toggleCompletion() {

        if tracksNextDue && item.repeatsDaily {

            DailyCompletion.closeNextDay(for: item)

        } else {

            item.checked.toggle()
        }

        saveChanges()
    }

    // MARK: - Date

    // A repeat carries no date of its own, so it shows the next day it is
    // actually due: today until today's is dealt with, then tomorrow. A
    // parked task has no date at all and says so.
    private var dateLabel: String {

        if item.repeatsDaily {
            return DailyCompletion.dayLabel(
                for: DailyCompletion.nextDueDate(for: item)
            )
        }

        guard let scheduledDate = item.scheduledDate
        else {
            return "No date"
        }

        return DailyCompletion.dayLabel(for: scheduledDate)
    }

    // MARK: - Delete Handling

    private func handleDelete() {

        if item.repeatsDaily {

            showingRemoveSheet = true

        } else {

            // A one-off delete is a single swipe away from undone by
            // retyping it, so it goes straight through without a prompt.
            deleteOneTimeItem()
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
