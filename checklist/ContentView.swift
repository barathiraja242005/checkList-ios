import SwiftUI
import SwiftData

enum AppRoute: Hashable {
    case newList
    case editList(UUID)
    case listDetail(UUID)
}

struct ContentView: View {

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - Today Items

    @Query(
        sort: [
            SortDescriptor(\TodayItem.position)
        ]
    )
    private var todayItems: [TodayItem]

    // MARK: - List Items

    @Query
    private var checklistItems: [ChecklistListItem]

    // MARK: - Add Item State

    // Kept per tab and remembered between launches.
    @AppStorage("todayShowsCompleted")
    private var showsCompleted = true

    @State private var isAddingItem = false
    @State private var newItemText = ""
    @State private var repeatEveryDay = false
    @State private var selectedTime: Date =
        Self.defaultTime
    @State private var hasSelectedTime = false
    @State private var showingTimePicker = false

    @FocusState
    private var isNewItemFieldFocused: Bool

    // MARK: - Default Time

    private static var defaultTime: Date {

        Calendar.current.date(
            bySettingHour: 21,
            minute: 30,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {

                    header

                    TaskFilterToggle(
                        showsCompleted: $showsCompleted
                    )
                    .padding(.top, 16)

                    todayItemsSection
                }
                .padding(.horizontal, 34)
                .padding(.top, 28)
                .padding(.bottom, 60)
            }
            .scrollIndicators(.hidden)
            .contentShape(Rectangle())
            .onTapGesture {
                dismissComposerIfEmpty()
            }
            .pageBackground()

            // Leaving the screen abandons a half-started item, so the
            // composer is not still sitting open on the way back.
            .onDisappear {
                cancelAddItem()
            }

        }
        .sheet(
            isPresented: $showingTimePicker
        ) {

            TimePickerView(
                itemName:
                    newItemText.isEmpty
                    ? "New item"
                    : newItemText,

                selectedTime: $selectedTime,

                onClear: {

                    hasSelectedTime = false

                    selectedTime =
                        Self.defaultTime
                },

                onDone: {

                    hasSelectedTime = true

                    addItem()
                }
            )
            .presentationDetents(
                [.height(490)]
            )
            .presentationDragIndicator(
                .hidden
            )
        }
    }
}

// MARK: - Visible Items

private extension ContentView {

    var visibleTodayItems: [TodayItem] {

        let calendar = Calendar.current

        let today = calendar.startOfDay(
            for: Date()
        )

        return todayItems.filter { item in

            // Later tasks are parked in their own section.
            if item.isLater {
                return false
            }

            if let skippedDate = item.skippedDate,
                calendar.isDate(
                    skippedDate,
                    inSameDayAs: today
                ) {

                return false
            }

            // A dated one-off belongs to its own day; once that day has
            // passed it moves to Overdue instead. Repeating and undated
            // tasks always sit on Today.
            guard
                !item.repeatsDaily,
                let scheduledDate = item.scheduledDate
            else {
                return true
            }

            return calendar.startOfDay(
                for: scheduledDate
            ) >= today
        }
    }

    // One-off tasks whose day has passed and that were never completed.
    var overdueTodayItems: [TodayItem] {

        let calendar = Calendar.current

        let today = calendar.startOfDay(
            for: Date()
        )

        return todayItems
            .filter { item in

                guard
                    !item.repeatsDaily,
                    !item.checked,
                    !item.isLater,
                    let scheduledDate = item.scheduledDate
                else {
                    return false
                }

                if let skippedDate = item.skippedDate,
                    calendar.isDate(
                        skippedDate,
                        inSameDayAs: today
                    ) {

                    return false
                }

                return calendar.startOfDay(
                    for: scheduledDate
                ) < today
            }
            .sorted { first, second in

                guard
                    let firstDate = first.scheduledDate,
                    let secondDate = second.scheduledDate
                else {
                    return false
                }

                return firstDate < secondDate
            }
    }

    // The filter only decides what is drawn — the "x of y done" count above
    // still speaks for the whole day.
    var displayedTodayItems: [TodayItem] {

        showsCompleted
            ? visibleTodayItems
            : visibleTodayItems.filter {
                !$0.checked
            }
    }

    var displayedScheduledChecklistItems: [ChecklistListItem] {

        showsCompleted
            ? scheduledTodayChecklistItems
            : scheduledTodayChecklistItems.filter {
                !$0.checked
            }
    }

    // MARK: - Scheduled List Items

    var scheduledTodayChecklistItems:
        [ChecklistListItem] {

        let calendar =
            Calendar.current

        return checklistItems
            .filter { item in

                guard let scheduledDate =
                        item.scheduledDate
                else {
                    return false
                }

                return calendar.isDateInToday(
                    scheduledDate
                )
            }
            .sorted { first, second in

                if first.hasScheduledTime !=
                    second.hasScheduledTime {

                    return first.hasScheduledTime
                }

                guard
                    let firstDate =
                        first.scheduledDate,

                    let secondDate =
                        second.scheduledDate

                else {
                    return false
                }

                return firstDate < secondDate
            }
    }

    // MARK: - Overdue List Items

    var overdueChecklistItems:
        [ChecklistListItem] {

        let today =
            Calendar.current.startOfDay(
                for: Date()
            )

        return checklistItems
            .filter { item in

                guard
                    let scheduledDate =
                        item.scheduledDate
                else {
                    return false
                }

                return scheduledDate < today &&
                    !item.checked
            }
            .sorted { first, second in

                guard
                    let firstDate =
                        first.scheduledDate,

                    let secondDate =
                        second.scheduledDate

                else {
                    return false
                }

                return firstDate < secondDate
            }
    }

    var totalTodayItems: Int {

        visibleTodayItems.count +
        scheduledTodayChecklistItems.count
    }

    var completedCount: Int {

        let todayCompleted =
            visibleTodayItems.filter {
                $0.checked
            }.count

        let listCompleted =
            scheduledTodayChecklistItems.filter {
                $0.checked
            }.count

        return todayCompleted +
            listCompleted
    }
}

// MARK: - Header

private extension ContentView {

    var header: some View {

        NavigationLink {

            TodayDatedView()

        } label: {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Today")
                    .font(
                        .system(
                            size: 26,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        .primary
                    )

                HStack(spacing: 4) {

                    Text(
                        Date(),
                        format:
                            .dateTime
                            .weekday(.wide)
                            .day()
                            .month(.wide)
                    )

                    Text("·")

                    Text(
                        "\(completedCount) of \(totalTodayItems) done"
                    )

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(
                        .system(
                            size: 10,
                            weight: .semibold
                        )
                    )
                }
                .font(
                    .system(size: 16)
                )
                .foregroundStyle(
                    .secondary
                )
                // Long weekday and month names plus a two-digit count can
                // wrap, so keep it on one line and shrink to fit instead.
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Today Section

private extension ContentView {

    var todayItemsSection: some View {

        VStack(spacing: 0) {

            Spacer()
                .frame(height: 20)

            ForEach(
                displayedTodayItems
            ) { item in

                TodayItemRow(
                    item: item
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

            ForEach(
                displayedScheduledChecklistItems
            ) { item in

                scheduledChecklistItemRow(
                    item
                )
            }

            if isAddingItem {

                addItemComposer

            } else {

                addItemRow
            }

            if !overdueChecklistItems.isEmpty
                || !overdueTodayItems.isEmpty {

                overdueSection
            }
        }
    }
}

// MARK: - Scheduled List Item Row

private extension ContentView {

    func scheduledChecklistItemRow(
        _ item: ChecklistListItem
    ) -> some View {

        HStack(spacing: 16) {

            Button {

                item.checked.toggle()

                item.list?.updateCounts()

                saveChanges()

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
                            ? Color.accentGreen
                            : Color.clear
                    )
                }
                .overlay {

                    if item.checked {

                        Image(
                            systemName:
                                "checkmark"
                        )
                        .font(
                            .system(
                                size: 10,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            .white
                        )
                    }
                }
                .frame(
                    width: 22,
                    height: 22
                )
            }
            .buttonStyle(.plain)

            NavigationLink {

                ChecklistListItemDetailView(
                    item: item
                )

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
                            item.checked
                                ? Color.secondary
                                : Color.primary
                        )
                        .strikethrough(
                            item.checked,
                            color: .secondary
                        )

                    // Says where the item came from, since these sit
                    // alongside Today's own items.
                    if let listTitle = item.list?.title {

                        Text(listTitle)
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

            if item.hasScheduledTime,
               let scheduledDate =
                    item.scheduledDate {

                Text(
                    scheduledDate,
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

// MARK: - Overdue

private extension ContentView {

    // Amber rather than red: overdue is a nudge, and red already means
    // delete elsewhere in the app.
    var overdueAccent: Color {

        Color.overdueAmber
    }

    var overdueSection: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            HStack(spacing: 6) {

                Image(
                    systemName: "exclamationmark.triangle.fill"
                )
                .font(.system(size: 12))

                Text("Overdue")
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
            }
            .foregroundStyle(overdueAccent)
            .padding(.top, 12)
            .padding(.bottom, 10)

            ForEach(
                overdueTodayItems
            ) { item in

                OverdueTodayItemRow(
                    item: item,
                    accent: overdueAccent
                )
            }

            ForEach(
                overdueChecklistItems
            ) { item in

                OverdueItemRow(
                    item: item,
                    accent: overdueAccent
                )
            }
        }
    }

}

// MARK: - Reordering

private extension ContentView {

    func moveItems(
        from source: IndexSet,
        to destination: Int
    ) {

        var reordered =
            visibleTodayItems

        reordered.move(
            fromOffsets: source,
            toOffset: destination
        )

        for (
            index,
            item
        ) in reordered.enumerated() {

            item.position = index
        }

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to reorder items: \(error)"
            )
        }
    }
}

// MARK: - Add Item Row

private extension ContentView {

    var addItemRow: some View {

        Button {

            isAddingItem = true
            newItemText = ""
            repeatEveryDay = false
            selectedTime =
                Self.defaultTime
            hasSelectedTime = false
            isNewItemFieldFocused = true

        } label: {

            HStack(spacing: 18) {

                Text("+")
                    .font(
                        .system(size: 19)
                    )
                    .foregroundStyle(
                        Color.accentGreen
                    )

                Text("Add item")
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
}

// MARK: - Add Item Composer

private extension ContentView {

    var addItemComposer: some View {

        VStack(spacing: 0) {

            HStack(spacing: 18) {

                Text("+")
                    .font(
                        .system(size: 19)
                    )
                    .foregroundStyle(
                        Color.accentGreen
                    )

                TextField(
                    "Add item",
                    text: $newItemText
                )
                .font(
                    .system(size: 17)
                )
                .submitLabel(.done)
                .focused(
                    $isNewItemFieldFocused
                )
                .onSubmit {

                    addItem()
                }
            }
            .frame(height: 53)

            HStack(spacing: 10) {

                timeChip
                repeatChip

                Spacer()
            }
            .padding(.leading, 40)
            .padding(.bottom, 14)
        }
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

    var timeChip: some View {

        Button {

            showingTimePicker = true

        } label: {

            Text(
                hasSelectedTime
                    ? selectedTime.formatted(
                        .dateTime
                            .hour(
                                .twoDigits(
                                    amPM: .omitted
                                )
                            )
                            .minute(
                                .twoDigits
                            )
                    )
                    : "Set time"
            )
            .font(
                .system(size: 15)
            )
            .foregroundStyle(
                hasSelectedTime
                    ? Color.accentGreen
                    : Color.secondary
            )
            .padding(
                .horizontal,
                16
            )
            .padding(
                .vertical,
                8
            )
            .background {

                Capsule()
                    .fill(
                        hasSelectedTime
                            ? Color.accentSoft
                            : Color(
                                .systemGray6
                            )
                    )
            }
        }
        .buttonStyle(.plain)
    }

    var repeatChip: some View {

        Button {

            repeatEveryDay.toggle()

        } label: {

            Text("Every day")
                .font(
                    .system(size: 15)
                )
                .foregroundStyle(
                    repeatEveryDay
                        ? Color.accentGreen
                        : Color.secondary
                )
                .padding(
                    .horizontal,
                    16
                )
                .padding(
                    .vertical,
                    8
                )
                .background {

                    Capsule()
                        .fill(
                            repeatEveryDay
                                ? Color.accentSoft
                                : Color(
                                    .systemGray6
                                )
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Today Item

private extension ContentView {

    // Tapping away from a composer with nothing typed in it closes it;
    // anything already typed is left alone rather than thrown away.
    func dismissComposerIfEmpty() {

        guard isAddingItem
        else {
            return
        }

        guard newItemText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        else {
            return
        }

        cancelAddItem()
    }

    func cancelAddItem() {

        guard isAddingItem
        else {
            return
        }

        isNewItemFieldFocused = false
        isAddingItem = false
        newItemText = ""
        repeatEveryDay = false
        selectedTime = Self.defaultTime
        hasSelectedTime = false
    }

    func addItem() {

        let trimmedText =
            newItemText.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard !trimmedText.isEmpty else {

            isAddingItem = false

            return
        }

        let newItem =
            TodayItem(
                text: trimmedText,
                remindAt:
                    hasSelectedTime
                        ? selectedTime
                        : nil,
                checked: false,
                repeatsDaily:
                    repeatEveryDay,

                // A one-off task belongs to the day it was made, so it can
                // fall into Overdue once that day passes. Repeating tasks are
                // regenerated daily and never carry a date.
                scheduledDate:
                    repeatEveryDay
                    ? nil
                    : Calendar.current.startOfDay(for: Date())
            )

        modelContext.insert(
            newItem
        )

        TodayItemOrdering.insertChronologically(
            newItem,
            into: todayItems
        )

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to save new item: \(error)"
            )
        }

        if hasSelectedTime {

            NotificationManager
                .requestAuthorization {

                    granted in

                    newItem.reminderEnabled =
                        granted

                    if granted {

                        NotificationManager
                            .scheduleReminder(
                                for: newItem
                            )
                    }

                    try? modelContext.save()
                }
        }

        newItemText = ""
        repeatEveryDay = false
        selectedTime =
            Self.defaultTime
        hasSelectedTime = false
        isAddingItem = false
        showingTimePicker = false
    }
}

// MARK: - Save

private extension ContentView {

    func saveChanges() {

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to save change: \(error)"
            )
        }
    }
}

// MARK: - Preview

#Preview {

    ContentView()
        .modelContainer(
            for: [
                TodayItem.self,
                ChecklistList.self,
                ChecklistListItem.self
            ],
            inMemory: true
        )
}
