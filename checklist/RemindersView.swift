import SwiftUI
import SwiftData

// Everything with "Remind me" switched on, from Today's own tasks and from
// inside lists, ordered by when it fires next.
struct RemindersView: View {

    @Query
    private var todayItems: [TodayItem]

    @Query
    private var checklistItems: [ChecklistListItem]

    @Environment(\.modelContext)
    private var modelContext

    // The blank task an Add reminder tap creates, held while its edit screen
    // is open so it can be pushed onto the stack.
    @State private var draft: TodayItem?

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {

                    header

                    if reminders.isEmpty {

                        emptyState

                    } else {

                        reminderRows
                    }

                    addReminderRow
                }
                // Keeps the column — and so the page background behind it —
                // the full width of the screen even when it holds nothing
                // but a line of placeholder text.
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

            .navigationDestination(
                item: $draft
            ) { item in

                ItemDetailView(
                    item: item,
                    backTitle: "Reminders",
                    isNewReminder: true
                )
            }
        }
    }
}

// MARK: - Reminder Entry

// A Today task and a list item are different models with the same job here,
// so they share one row type.
enum ReminderEntry: Identifiable {

    case todayItem(TodayItem)
    case listItem(ChecklistListItem)

    var id: UUID {

        switch self {

        case .todayItem(let item):
            return item.id

        case .listItem(let item):
            return item.id
        }
    }

    var text: String {

        switch self {

        case .todayItem(let item):
            return item.text

        case .listItem(let item):
            return item.text
        }
    }

    // The time shown on the right of the row.
    var time: Date? {

        switch self {

        case .todayItem(let item):
            return item.remindAt

        case .listItem(let item):
            return item.scheduledDate
        }
    }

    // When this reminder next goes off, or nil when it has already been and
    // gone — a one-off only fires once, so once its time has passed there is
    // nothing left to list. A daily repeat always has a next one: today's if
    // it is still to come, otherwise tomorrow's.
    var nextFireDate: Date? {

        let calendar = Calendar.current
        let now = Date()

        switch self {

        case .todayItem(let item):

            guard let remindAt = item.remindAt
            else {
                return nil
            }

            if item.repeatsDaily {

                let todayFire = time(
                    of: remindAt,
                    on: now
                )

                // Today's is gone if it has already fired, and equally if the
                // day was dropped from the list.
                let settledForToday =
                    todayFire <= now
                    || DailyCompletion.isSkipped(item, on: now)

                guard settledForToday
                else {
                    return todayFire
                }

                return calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: todayFire
                )
            }

            let fire = time(
                of: remindAt,
                on: item.scheduledDate ?? now
            )

            // A weekly, fortnightly or monthly reminder always has another
            // one coming, so it rolls forward rather than dropping off.
            if item.recurrence.advancesItsOwnDate {

                return item.recurrence.nextDate(
                    onOrAfter: now,
                    from: fire
                )
            }

            return fire > now ? fire : nil

        case .listItem(let item):

            guard let scheduledDate = item.scheduledDate
            else {
                return nil
            }

            return scheduledDate > now ? scheduledDate : nil
        }
    }

    private func time(
        of time: Date,
        on day: Date
    ) -> Date {

        let calendar = Calendar.current

        return calendar.date(
            bySettingHour:
                calendar.component(.hour, from: time),
            minute:
                calendar.component(.minute, from: time),
            second: 0,
            of: day
        ) ?? time
    }

    // Says where the reminder came from, or how often it repeats.
    var subtitle: String? {

        let calendar = Calendar.current

        switch self {

        case .todayItem(let item):

            if item.recurrence != .none {
                return item.recurrence.label
            }

            guard
                let scheduledDate = item.scheduledDate,
                !calendar.isDateInToday(scheduledDate)
            else {
                return nil
            }

            return scheduledDate.formatted(
                .dateTime
                    .weekday(.abbreviated)
                    .day()
                    .month(.abbreviated)
            )

        case .listItem(let item):

            let listTitle = item.list?.title

            guard
                let scheduledDate = item.scheduledDate,
                !calendar.isDateInToday(scheduledDate)
            else {
                return listTitle
            }

            let day = scheduledDate.formatted(
                .dateTime
                    .weekday(.abbreviated)
                    .day()
                    .month(.abbreviated)
            )

            guard let listTitle
            else {
                return day
            }

            return "\(listTitle) · \(day)"
        }
    }
}

// MARK: - Contents

private extension RemindersView {

    var reminders: [ReminderEntry] {

        let todayReminders =
            todayItems
                .filter {
                    $0.reminderEnabled
                }
                .map {
                    ReminderEntry.todayItem($0)
                }

        let listReminders =
            checklistItems
                .filter {
                    $0.reminderEnabled
                }
                .map {
                    ReminderEntry.listItem($0)
                }

        return (todayReminders + listReminders)
            .compactMap { entry -> (ReminderEntry, Date)? in

                guard let fire = entry.nextFireDate
                else {
                    return nil
                }

                return (entry, fire)
            }
            .sorted {
                $0.1 < $1.1
            }
            .map {
                $0.0
            }
    }
}

// MARK: - Header

private extension RemindersView {

    var header: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text("Reminders")
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
                reminders.count == 1
                    ? "1 coming up"
                    : "\(reminders.count) coming up"
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

// MARK: - Rows

private extension RemindersView {

    var reminderRows: some View {

        VStack(spacing: 0) {

            Spacer()
                .frame(height: 20)

            ForEach(
                reminders
            ) { entry in

                reminderRow(entry)
            }
        }
    }

    func reminderRow(
        _ entry: ReminderEntry
    ) -> some View {

        NavigationLink {

            destination(for: entry)

        } label: {

            HStack(spacing: 16) {

                Image(
                    systemName: "bell.fill"
                )
                .font(
                    .system(size: 13)
                )
                .foregroundStyle(
                    Color.accentGreen
                )
                .frame(width: 22)

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text(entry.text)
                        .font(
                            .system(size: 17)
                        )
                        .foregroundStyle(
                            Color.primary
                        )

                    if let subtitle = entry.subtitle {

                        Text(subtitle)
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

                if let time = entry.time {

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
                    .foregroundStyle(
                        .secondary
                    )
                    .fixedSize()
                }
            }
            .padding(.leading, 2)
            // Same breathing room under a row as the Tasks tab, so the line
            // beneath the title is not sitting on the separator.
            .padding(.top, 7)
            .padding(.bottom, 10)
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
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func destination(
        for entry: ReminderEntry
    ) -> some View {

        switch entry {

        case .todayItem(let item):

            ItemDetailView(
                item: item,
                backTitle: "Reminders"
            )

        case .listItem(let item):

            ChecklistListItemDetailView(
                item: item
            )
        }
    }

    // Adding a reminder is adding a task that happens to start on the edit
    // screen, with the switch already chosen and waiting on a date or time.
    var addReminderRow: some View {

        Button {

            let newItem = TodayItem(text: "")

            modelContext.insert(newItem)

            draft = newItem

        } label: {

            HStack(spacing: 18) {

                Text("+")
                    .font(
                        .system(size: 19)
                    )
                    .foregroundStyle(
                        Color.accentGreen
                    )

                Text("Add reminder")
                    .font(
                        .system(
                            size: 15,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        Color.accentGreen
                    )

                Spacer()
            }
            .frame(height: 58)
        }
        .buttonStyle(.plain)
    }

    var emptyState: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("Nothing coming up")
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
                "Set a time on a task and turn on Remind me. Reminders drop off here once they have gone off."
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

// MARK: - Preview

#Preview {

    RemindersView()
        .modelContainer(
            for: [
                TodayItem.self,
                ChecklistList.self,
                ChecklistListItem.self
            ],
            inMemory: true
        )
}
