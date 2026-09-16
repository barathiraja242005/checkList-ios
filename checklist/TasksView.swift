import SwiftUI
import SwiftData

// Every task that stands on its own — Today's, the daily repeats, and the
// ones parked under My Tasks. Anything living inside a list belongs to that
// list and is not shown here.
//
// Rows stand for a single day of a task rather than the task itself: a repeat
// shows the next day still open, and the days already closed are listed
// underneath when the filter asks for them.
struct TasksView: View {

    @Query(
        sort: [
            SortDescriptor(\TodayItem.position)
        ]
    )
    private var todayItems: [TodayItem]

    // Past days are snapshotted into occurrences by the nightly rollover,
    // which is where a repeat's history comes from.
    @Query(
        sort: [
            SortDescriptor(
                \Occurrence.periodDate,
                order: .reverse
            )
        ]
    )
    private var occurrences: [Occurrence]

    @Environment(\.modelContext)
    private var modelContext

    @AppStorage("tasksShowsCompleted")
    private var showsCompleted = false

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {

                    header

                    TaskFilterChips(
                        showsCompleted: $showsCompleted
                    )
                    .padding(.top, 16)

                    if openTasks.isEmpty && !showsCompleted {

                        emptyState

                    } else {

                        openRows
                    }

                    if showsCompleted {

                        completedSection
                    }
                }
                // Keeps the column — and the page background behind it — the
                // full width of the screen even when it holds nothing but a
                // line of placeholder text.
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(.horizontal, 34)
                .padding(.top, 28)
                .padding(.bottom, 60)
            }
            .scrollIndicators(.hidden)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .pageBackground()
        }
    }
}

// MARK: - Completed Instance

// One day of a task that has been closed. Days still held on the task itself
// carry it, so they can be reopened; days that have rolled into history are a
// record and stay put.
struct CompletedInstance: Identifiable {

    let id: String
    let text: String
    let date: Date
    let time: Date?
    let item: TodayItem?
}

// MARK: - Contents

private extension TasksView {

    // Today's work first, in the order Today itself shows it, then the
    // undated My Tasks pile underneath.
    var tasks: [TodayItem] {

        todayItems.sorted { first, second in

            if first.isLater != second.isLater {
                return !first.isLater
            }

            return first.position < second.position
        }
    }

    // A repeat is always open — the row stands for its next free day, not for
    // one already ticked off.
    var openTasks: [TodayItem] {

        tasks.filter { item in

            item.repeatsDaily
                ? true
                : !item.checked
        }
    }

    var completedInstances: [CompletedInstance] {

        var instances: [CompletedInstance] = []

        // Days closed on the task itself: today's, plus any closed early.
        for item in tasks {

            if item.repeatsDaily {

                for date in DailyCompletion.completedDates(for: item) {

                    instances.append(
                        CompletedInstance(
                            id: "live-\(item.id)-\(date.timeIntervalSince1970)",
                            text: item.text,
                            date: date,
                            time: item.remindAt,
                            item: item
                        )
                    )
                }

            } else if item.checked {

                instances.append(
                    CompletedInstance(
                        id: "live-\(item.id)",
                        text: item.text,
                        date:
                            item.scheduledDate
                            ?? DailyCompletion.day(Date()),
                        time: item.remindAt,
                        item: item
                    )
                )
            }
        }

        // Everything the rollover has already filed away.
        for occurrence in occurrences {

            for occurrenceItem in occurrence.items where occurrenceItem.checked {

                instances.append(
                    CompletedInstance(
                        id: "history-\(occurrenceItem.id)",
                        text: occurrenceItem.text,
                        date: occurrence.periodDate,
                        time: occurrenceItem.remindAt,
                        item: nil
                    )
                )
            }
        }

        return instances.sorted {
            $0.date > $1.date
        }
    }

    var completedCount: Int {

        completedInstances.count
    }
}

// MARK: - Header

private extension TasksView {

    var header: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text("Tasks")
                .font(
                    .system(
                        size: 26,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    .primary
                )

            Text(
                openTasks.count == 1
                    ? "1 task open"
                    : "\(openTasks.count) tasks open"
            )
            .font(
                .system(size: 16)
            )
            .foregroundStyle(
                .secondary
            )
        }
    }
}

// MARK: - Open Rows

private extension TasksView {

    var openRows: some View {

        VStack(spacing: 0) {

            Spacer()
                .frame(height: 20)

            ForEach(
                openTasks
            ) { item in

                TodayItemRow(
                    item: item,
                    showsDate: true,
                    tracksNextDue: true
                )
                .frame(minHeight: 47)
                .overlay(
                    Rectangle()
                        .fill(
                            Color(.systemGray5)
                        )
                        .frame(height: 1),
                    alignment: .bottom
                )
            }
        }
    }

    var emptyState: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("Nothing open")
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .secondary
                )

            Text(
                "Switch to All to see what you have finished."
            )
            .font(
                .system(size: 15)
            )
            .foregroundStyle(
                .secondary
            )
        }
        .padding(.top, 36)
    }
}

// MARK: - Completed Rows

private extension TasksView {

    var completedSection: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            Text("Completed")
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .secondary
                )
                .padding(.top, 22)
                .padding(.bottom, 4)

            if completedInstances.isEmpty {

                Text("Nothing finished yet.")
                    .font(
                        .system(size: 15)
                    )
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)

            } else {

                ForEach(
                    completedInstances
                ) { instance in

                    completedRow(instance)
                }
            }
        }
    }

    func completedRow(
        _ instance: CompletedInstance
    ) -> some View {

        HStack(spacing: 16) {

            Button {

                guard let item = instance.item
                else {
                    return
                }

                DailyCompletion.reopen(
                    instance.date,
                    for: item
                )

                saveChanges()

            } label: {

                CheckmarkBox(
                    isChecked: true
                )
            }
            .buttonStyle(.plain)
            // A day that has rolled into history is a record of what
            // happened, so it is shown rather than edited.
            .disabled(instance.item == nil)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(instance.text)
                    .font(
                        .system(size: 17)
                    )
                    .foregroundStyle(.secondary)
                    .strikethrough(
                        true,
                        color: .secondary
                    )

                Text(
                    DailyCompletion.dayLabel(
                        for: instance.date
                    )
                )
                .font(
                    .system(size: 11)
                )
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

            if let time = instance.time {

                Text(
                    time,
                    format:
                        .dateTime
                        .hour()
                        .minute()
                )
                .font(
                    .system(size: 15)
                )
                .foregroundStyle(.secondary)
                .fixedSize()
            }
        }
        .padding(.leading, 2)
        .padding(.vertical, 7)
        .frame(minHeight: 47)
        .overlay(
            Rectangle()
                .fill(
                    Color(.systemGray5)
                )
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - Save

private extension TasksView {

    func saveChanges() {

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to save completion change: \(error)"
            )
        }
    }
}

// MARK: - Preview

#Preview {

    TasksView()
        .modelContainer(
            for: [
                TodayItem.self,
                ChecklistList.self,
                ChecklistListItem.self
            ],
            inMemory: true
        )
}
