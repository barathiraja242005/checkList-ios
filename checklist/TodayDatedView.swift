import SwiftUI
import SwiftData

struct TodayDatedView: View {

    // MARK: - Data

    @Query(
        sort: [
            SortDescriptor(\TodayItem.position)
        ]
    )
    private var todayItems: [TodayItem]

    @Query(
        sort: [
            SortDescriptor(\OccurrenceItem.position)
        ]
    )
    private var allOccurrenceItems: [OccurrenceItem]

    @Query
    private var occurrences: [Occurrence]

    @Query
    private var checklistItems: [ChecklistListItem]

    // MARK: - Environment

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - State

    @State private var selectedDate =
        Calendar.current.startOfDay(
            for: Date()
        )

    @State private var isAddingItem = false
    @State private var newItemText = ""
    @State private var repeatEveryDay = false
    @State private var selectedTime: Date =
        Self.defaultTime
    @State private var hasSelectedTime = false
    @State private var showingTimePicker = false

    // MARK: - Constants

    private static var today: Date {
        Calendar.current.startOfDay(
            for: Date()
        )
    }

    private static var defaultTime: Date {
        Calendar.current.date(
            bySettingHour: 21,
            minute: 30,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(
            selectedDate
        )
    }

    private var isPastDate: Bool {
        selectedDate < Self.today
    }

    private var isFutureDate: Bool {
        selectedDate > Self.today
    }

    // MARK: - Body

    var body: some View {

        VStack(
            spacing: 0
        ) {

            topBar

            fullDateTitle

            dateStrip

            progressHeader

            itemsList
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)

        .onAppear {
            ensureOccurrenceForSelectedDate()
        }

        .onChange(
            of: selectedDate
        ) { _, _ in

            isAddingItem = false
            newItemText = ""
            repeatEveryDay = false
            selectedTime = Self.defaultTime
            hasSelectedTime = false

            ensureOccurrenceForSelectedDate()
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
                    selectedTime = Self.defaultTime
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

// MARK: - Top Bar

private extension TodayDatedView {

    var topBar: some View {

        HStack {

            Button {

                dismiss()

            } label: {

                HStack(spacing: 4) {

                    Image(
                        systemName: "chevron.left"
                    )
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )

                    Text("Today")
                        .font(
                            .system(size: 17)
                        )
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }
}

// MARK: - Full Date Title

private extension TodayDatedView {

    var fullDateTitle: some View {

        Text(
            selectedDate,
            format:
                .dateTime
                .weekday(.wide)
                .month(.wide)
                .day()
                .year()
        )
        .font(
            .system(
                size: 28,
                weight: .bold
            )
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 18)
    }
}

// MARK: - Date Strip

private extension TodayDatedView {

    var dateStrip: some View {

        HStack(
            spacing: 0
        ) {

            ForEach(
                visibleDates,
                id: \.self
            ) { date in

                dateButton(
                    for: date
                )
                .frame(
                    maxWidth: .infinity
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }

    // Shows only:
    // 2 days before
    // selected day
    // 2 days after

    var visibleDates: [Date] {

        let calendar = Calendar.current

        return (-2...2).compactMap { offset in

            calendar.date(
                byAdding: .day,
                value: offset,
                to: selectedDate
            )
        }
    }

    func dateButton(
        for date: Date
    ) -> some View {

        let calendar = Calendar.current

        let isSelected =
            calendar.isDate(
                date,
                inSameDayAs: selectedDate
            )

        return Button {

            selectedDate =
                calendar.startOfDay(
                    for: date
                )

        } label: {

            VStack(
                spacing: 4
            ) {

                Text(
                    date,
                    format:
                        .dateTime
                        .weekday(.abbreviated)
                )
                .font(
                    .system(
                        size: 12,
                        weight: .medium
                    )
                )

                Text(
                    date,
                    format:
                        .dateTime
                        .day()
                )
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )
            }
            .foregroundStyle(
                isSelected
                ? Color.white
                : Color.primary
            )
            .frame(
                width: 48,
                height: 50
            )
            .background {

                if isSelected {

                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                    .fill(
                        Color(
                            red: 0.12,
                            green: 0.12,
                            blue: 0.12
                        )
                    )
                }
            }
        }
        .buttonStyle(.plain)
    }
}
// MARK: - Progress

private extension TodayDatedView {

    var progressHeader: some View {

        HStack {

            Text(
                "\(completedCount)/\(visibleItemCount)"
            )
            .font(
                .system(
                    size: 15,
                    weight: .semibold
                )
            )
            .foregroundStyle(.secondary)

            Spacer()

            if visibleItemCount > 0 {

                Text(
                    "\(progressPercentage)%"
                )
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }

    var progressPercentage: Int {

        guard visibleItemCount > 0 else {
            return 0
        }

        return Int(
            Double(completedCount)
            / Double(visibleItemCount)
            * 100
        )
    }
}

// MARK: - Items List

private extension TodayDatedView {

    var itemsList: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 0
            ) {

                // MARK: Today's Items

                if isToday {

                    ForEach(
                        todayItems
                    ) { item in

                        TodayItemRow(
                            item: item
                        )
                    }
                }

                // MARK: Occurrence Items

                if !isToday {

                    if let occurrence =
                        occurrenceForSelectedDate {

                        ForEach(
                            occurrence.items.sorted {
                                $0.position < $1.position
                            }
                        ) { item in

                            OccurrenceItemRow(
                                item: item,
                                isPast: isPastDate,
                                isFuture: isFutureDate
                            )
                        }
                    }
                }

                // MARK: Scheduled List Items

                ForEach(
                    scheduledChecklistItems
                ) { item in

                    scheduledChecklistItemRow(
                        item
                    )
                }

                // MARK: Overdue

                if isToday &&
                    !overdueChecklistItems.isEmpty {

                    overdueSection
                }

                // MARK: Add Item

                addItemSection
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
    }
}

// MARK: - Scheduled Checklist Items

private extension TodayDatedView {

    var scheduledChecklistItems:
        [ChecklistListItem] {

        let calendar = Calendar.current

        return checklistItems
            .filter { item in

                guard
                    let scheduledDate =
                        item.scheduledDate
                else {
                    return false
                }

                return calendar.isDate(
                    scheduledDate,
                    inSameDayAs: selectedDate
                )
            }
            .sorted {
                $0.position < $1.position
            }
    }

    func scheduledChecklistItemRow(
        _ item: ChecklistListItem
    ) -> some View {

        NavigationLink {

            ChecklistListItemDetailView(
                item: item
            )

        } label: {

            HStack(
                spacing: 12
            ) {

                Button {

                    item.checked.toggle()
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
                                systemName:
                                    "checkmark"
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

                Text(item.text)
                    .font(
                        .system(size: 16)
                    )
                    .foregroundStyle(
                        item.checked
                        ? .secondary
                        : .primary
                    )
                    .strikethrough(
                        item.checked,
                        color: .secondary
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

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
                        .system(size: 16)
                    )
                    .foregroundStyle(.secondary)
                    .fixedSize()
                }
            }
            .frame(
                minHeight: 52
            )
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
}

// MARK: - Overdue

private extension TodayDatedView {

    var overdueChecklistItems:
        [ChecklistListItem] {

        let today = Self.today

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

    var overdueSection: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            Text("Overdue")
                .font(
                    .system(
                        size: 18,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.primary)
                .padding(.top, 24)
                .padding(.bottom, 8)

            ForEach(
                overdueChecklistItems
            ) { item in

                overdueChecklistItemRow(
                    item
                )
            }
        }
    }

    func overdueChecklistItemRow(
        _ item: ChecklistListItem
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack(
                spacing: 12
            ) {

                RoundedRectangle(
                    cornerRadius: 5,
                    style: .continuous
                )
                .stroke(
                    Color(.systemGray3),
                    lineWidth: 1.5
                )
                .frame(
                    width: 22,
                    height: 22
                )

                Text(item.text)
                    .font(
                        .system(size: 16)
                    )
                    .foregroundStyle(.primary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }

            HStack {

                if let scheduledDate =
                    item.scheduledDate {

                    Text(
                        "Due " +
                        scheduledDate.formatted(
                            .dateTime
                                .month(.abbreviated)
                                .day()
                                .year()
                        )
                    )
                    .font(
                        .system(size: 12)
                    )
                    .foregroundStyle(.secondary)
                }

                Spacer()

                NavigationLink {

                    ChecklistListItemDetailView(
                        item: item
                    )

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
                                red: 0.20,
                                green: 0.48,
                                blue: 0.37
                            )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 34)
        }
        .padding(.vertical, 10)
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

// MARK: - Add Item

private extension TodayDatedView {

    var addItemSection: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            if isAddingItem {

                VStack(
                    spacing: 12
                ) {

                    TextField(
                        "Item name",
                        text: $newItemText
                    )
                    .font(
                        .system(size: 16)
                    )
                    .textFieldStyle(.plain)
                    .padding(
                        .vertical,
                        12
                    )
                    .overlay(
                        Rectangle()
                            .fill(
                                Color(.systemGray5)
                            )
                            .frame(height: 1),
                        alignment: .bottom
                    )

                    HStack {

                        Button {

                            repeatEveryDay.toggle()

                        } label: {

                            HStack(
                                spacing: 6
                            ) {

                                Image(
                                    systemName:
                                        repeatEveryDay
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )

                                Text("Every day")
                                    .font(
                                        .system(size: 14)
                                    )
                            }
                            .foregroundStyle(
                                repeatEveryDay
                                ? Color(
                                    red: 0.20,
                                    green: 0.48,
                                    blue: 0.37
                                )
                                : .secondary
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if hasSelectedTime {

                            Button {

                                showingTimePicker = true

                            } label: {

                                Text(
                                    selectedTime,
                                    format:
                                        .dateTime
                                        .hour()
                                        .minute()
                                )
                                .font(
                                    .system(size: 14)
                                )
                                .foregroundStyle(
                                    Color(
                                        red: 0.20,
                                        green: 0.48,
                                        blue: 0.37
                                    )
                                )
                            }
                            .buttonStyle(.plain)

                        } else {

                            Button {

                                showingTimePicker = true

                            } label: {

                                Text("Set time")
                                    .font(
                                        .system(size: 14)
                                    )
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {

                        Button("Cancel") {

                            isAddingItem = false
                            newItemText = ""
                            repeatEveryDay = false
                            hasSelectedTime = false
                            selectedTime = Self.defaultTime
                        }
                        .foregroundStyle(.secondary)

                        Spacer()

                        Button("Add") {

                            addItem()
                        }
                        .font(
                            .system(
                                size: 16,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            newItemText
                                .trimmingCharacters(
                                    in:
                                        .whitespacesAndNewlines
                                )
                                .isEmpty
                            ? .secondary
                            : Color(
                                red: 0.20,
                                green: 0.48,
                                blue: 0.37
                            )
                        )
                        .disabled(
                            newItemText
                                .trimmingCharacters(
                                    in:
                                        .whitespacesAndNewlines
                                )
                                .isEmpty
                        )
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 12)

            } else {

                Button {

                    isAddingItem = true

                } label: {

                    HStack {

                        Image(
                            systemName: "plus"
                        )

                        Text("Add item")
                            .font(
                                .system(size: 16)
                            )
                    }
                    .foregroundStyle(
                        Color(
                            red: 0.20,
                            green: 0.48,
                            blue: 0.37
                        )
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .frame(
                        minHeight: 52
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Occurrence

private extension TodayDatedView {

    var occurrenceForSelectedDate:
        Occurrence? {

        let calendar = Calendar.current

        return occurrences.first {
            calendar.isDate(
                $0.periodDate,
                inSameDayAs: selectedDate
            )
        }
    }

    func ensureOccurrenceForSelectedDate() {

        guard !isToday else {
            return
        }

        let calendar = Calendar.current

        if occurrenceForSelectedDate != nil {
            return
        }

        let newOccurrence =
            Occurrence(
                periodDate:
                    calendar.startOfDay(
                        for: selectedDate
                    )
            )

        modelContext.insert(
            newOccurrence
        )

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to create occurrence: \(error)"
            )
        }
    }
}

// MARK: - Counts

private extension TodayDatedView {

    var completedCount: Int {

        let todayCompleted =
            isToday
            ? todayItems.filter {
                $0.checked
            }.count
            : occurrenceForSelectedDate?
                .items
                .filter {
                    $0.checked
                }
                .count ?? 0

        let checklistCompleted =
            scheduledChecklistItems.filter {
                $0.checked
            }.count

        return todayCompleted
            + checklistCompleted
    }

    var visibleItemCount: Int {

        let todayCount =
            isToday
            ? todayItems.count
            : occurrenceForSelectedDate?
                .items
                .count ?? 0

        return todayCount
            + scheduledChecklistItems.count
    }
}

// MARK: - Add Item Logic

private extension TodayDatedView {

    func addItem() {

        let trimmed =
            newItemText.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return
        }

        let calendar = Calendar.current

        let time =
            hasSelectedTime
            ? selectedTime
            : Self.defaultTime

        let dateWithTime =
            calendar.date(
                bySettingHour:
                    calendar.component(
                        .hour,
                        from: time
                    ),
                minute:
                    calendar.component(
                        .minute,
                        from: time
                    ),
                second: 0,
                of: selectedDate
            ) ?? selectedDate

        let newItem =
            TodayItem(
                text: trimmed,
                remindAt:
                    hasSelectedTime
                    ? dateWithTime
                    : nil,
                checked: false,
                position:
                    todayItems.count,
                repeatsDaily:
                    repeatEveryDay
            )

        modelContext.insert(
            newItem
        )

        if hasSelectedTime {

            newItem.remindAt =
                dateWithTime
        }

        if repeatEveryDay {

            newItem.repeatsDaily = true
        }

        if hasSelectedTime {

            NotificationManager.scheduleReminder(
                for: newItem
            )
        }

        saveChanges()

        isAddingItem = false
        newItemText = ""
        repeatEveryDay = false
        hasSelectedTime = false
        selectedTime = Self.defaultTime
    }
}

// MARK: - Save

private extension TodayDatedView {

    func saveChanges() {

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to save changes: \(error)"
            )
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        TodayDatedView()
    }
    .modelContainer(
        for: [
            TodayItem.self,
            Occurrence.self,
            OccurrenceItem.self,
            ChecklistList.self,
            ChecklistListItem.self
        ],
        inMemory: true
    )
}
