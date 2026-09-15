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
                HStack(spacing: 3) {
                    Image(
                        systemName: "chevron.left"
                    )
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )

                    Text("Home")
                }
                .font(
                    .system(size: 17)
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
}

// MARK: - Full Date Title

private extension TodayDatedView {

    var fullDateTitle: some View {
        Text(
            selectedDate.formatted(
                .dateTime
                    .weekday(.wide)
                    .day()
                    .month(.wide)
            )
        )
        .font(
            .system(
                size: 28,
                weight: .bold
            )
        )
        .foregroundStyle(.primary)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(.horizontal, 32)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

// MARK: - Date Strip

private extension TodayDatedView {

    var dateStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 8) {
                    ForEach(
                        dateStripDates,
                        id: \.self
                    ) { date in
                        dateButton(
                            for: date
                        )
                        .id(date)
                    }
                }
                .padding(.horizontal, 23)
                .padding(.vertical, 6)
            }
            .frame(height: 75)
            .onAppear {
                proxy.scrollTo(
                    selectedDate,
                    anchor: .center
                )
            }
            .onChange(
                of: selectedDate
            ) { _, newDate in
                withAnimation(
                    .easeInOut(
                        duration: 0.2
                    )
                ) {
                    proxy.scrollTo(
                        newDate,
                        anchor: .center
                    )
                }
            }
        }
    }

    var dateStripDates: [Date] {
        let calendar = Calendar.current

        return (-365...30).compactMap {
            offset in

            calendar.date(
                byAdding: .day,
                value: offset,
                to: Self.today
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

            VStack(spacing: 4) {

                Text(
                    date.formatted(
                        .dateTime
                            .weekday(
                                .abbreviated
                            )
                    )
                )
                .font(
                    .system(size: 13)
                )

                Text(
                    date.formatted(
                        .dateTime.day()
                    )
                )
                .font(
                    .system(
                        size: 18,
                        weight: .medium
                    )
                )
            }
            .foregroundStyle(
                isSelected
                ? Color.white
                : Color.primary
            )
            .frame(
                width: 64,
                height: 59
            )
            .background {

                if isSelected {
                    RoundedRectangle(
                        cornerRadius: 12,
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
        HStack(spacing: 8) {

            Text(
                "\(completedCount) of \(visibleItemCount)"
            )
            .font(
                .system(
                    size: 18,
                    weight: .bold
                )
            )

            Text(
                isToday
                ? "done today"
                : "done"
            )
            .font(
                .system(size: 17)
            )
            .foregroundStyle(
                .secondary
            )

            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 17)
    }

    var visibleTodayItems: [TodayItem] {
        let calendar = Calendar.current
        let today = Self.today

        return todayItems.filter { item in

            guard let skippedDate =
                item.skippedDate
            else {
                return true
            }

            return !calendar.isDate(
                skippedDate,
                inSameDayAs: today
            )
        }
    }

    var scheduledChecklistItems: [ChecklistListItem] {

        let calendar = Calendar.current

        return checklistItems
            .filter { item in

                guard let scheduledDate =
                    item.scheduledDate
                else {
                    return false
                }

                return calendar.isDate(
                    scheduledDate,
                    inSameDayAs: selectedDate
                )
            }
            .sorted { first, second in

                let firstTime =
                    first.scheduledDate ?? Date.distantFuture

                let secondTime =
                    second.scheduledDate ?? Date.distantFuture

                return firstTime < secondTime
            }
    }

    var completedCount: Int {

        let todayCompleted =
            isToday
            ? visibleTodayItems.filter {
                $0.checked
            }.count
            : selectedOccurrenceItems.filter {
                $0.checked
            }.count

        let scheduledCompleted =
            scheduledChecklistItems.filter {
                $0.checked
            }.count

        return todayCompleted + scheduledCompleted
    }

    var visibleItemCount: Int {

        let existingCount =
            isToday
            ? visibleTodayItems.count
            : selectedOccurrenceItems.count

        return existingCount +
            scheduledChecklistItems.count
    }
}

// MARK: - Occurrence

private extension TodayDatedView {

    var selectedOccurrence: Occurrence? {

        let calendar =
            Calendar.current

        return occurrences.first {
            occurrence in

            calendar.isDate(
                occurrence.periodDate,
                inSameDayAs: selectedDate
            )
        }
    }

    var selectedOccurrenceItems:
        [OccurrenceItem] {

        guard
            let occurrence =
                selectedOccurrence
        else {
            return []
        }

        return allOccurrenceItems
            .filter { item in

                guard
                    let itemOccurrence =
                        item.occurrence
                else {
                    return false
                }

                return itemOccurrence ===
                    occurrence
            }
            .sorted {
                $0.position <
                    $1.position
            }
    }

    func ensureOccurrenceForSelectedDate() {

        guard isFutureDate
        else {
            return
        }

        let occurrence: Occurrence

        if let existingOccurrence =
            selectedOccurrence {

            occurrence =
                existingOccurrence

        } else {

            occurrence =
                Occurrence(
                    periodDate:
                        Calendar.current
                        .startOfDay(
                            for: selectedDate
                        )
                )

            modelContext.insert(
                occurrence
            )
        }

        let recurringItems =
            todayItems
                .filter {
                    $0.repeatsDaily
                }
                .sorted {
                    $0.position <
                        $1.position
                }

        for todayItem in recurringItems {

            let alreadyExists =
                occurrence.items.contains {
                    occurrenceItem in

                    occurrenceItem.sourceItemID ==
                        todayItem.id
                }

            if alreadyExists {
                continue
            }

            let nextPosition =
                (
                    occurrence.items
                        .map {
                            $0.position
                        }
                        .max() ?? -1
                ) + 1

            let occurrenceItem =
                OccurrenceItem(
                    sourceItemID:
                        todayItem.id,
                    text:
                        todayItem.text,
                    remindAt:
                        copyTime(
                            from:
                                todayItem.remindAt,
                            to:
                                selectedDate
                        ),
                    position:
                        nextPosition,
                    checked: false,
                    checkedAt: nil,
                    occurrence:
                        occurrence
                )

            occurrence.items.append(
                occurrenceItem
            )
        }

        do {
            try modelContext.save()
        } catch {
            print(
                "Failed to generate future occurrence: \(error)"
            )
        }
    }

    func copyTime(
        from sourceDate: Date?,
        to targetDate: Date
    ) -> Date? {

        guard let sourceDate
        else {
            return nil
        }

        let calendar =
            Calendar.current

        let hour =
            calendar.component(
                .hour,
                from: sourceDate
            )

        let minute =
            calendar.component(
                .minute,
                from: sourceDate
            )

        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: targetDate
        )
    }
}

// MARK: - Items List

private extension TodayDatedView {

    var itemsList: some View {

        ScrollView {

            VStack(
                spacing: 0
            ) {

                if isToday {

                    ForEach(
                        visibleTodayItems
                    ) { item in

                        TodayItemRow(
                            item: item
                        )
                        .frame(height: 59)
                    }

                } else {

                    ForEach(
                        selectedOccurrenceItems
                    ) { item in

                        OccurrenceItemRow(
                            item: item,
                            isPast: isPastDate,
                            isFuture: isFutureDate
                        )
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

                // MARK: Add Item

                if isToday {

                    if isAddingItem {
                        composer
                    } else {
                        addItemButton
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.never)
    }

    func scheduledChecklistItemRow(
        _ item: ChecklistListItem
    ) -> some View {

        HStack(spacing: 12) {

            Button {
                item.checked.toggle()

                if let list = item.list {
                    list.updateCounts()
                }

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

            NavigationLink {

                ChecklistListItemDetailView(
                    item: item
                )

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

            if let scheduledDate =
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
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding(.leading, 2)
        .frame(minHeight: 59)
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

// MARK: - Add Item Button

private extension TodayDatedView {

    var addItemButton: some View {

        Button {

            isAddingItem = true
            newItemText = ""
            repeatEveryDay = false
            selectedTime = Self.defaultTime
            hasSelectedTime = false

        } label: {

            HStack(spacing: 18) {

                Text("+")
                    .font(
                        .system(size: 21)
                    )
                    .foregroundStyle(
                        .secondary
                    )

                Text("Add item")
                    .font(
                        .system(size: 18)
                    )
                    .foregroundStyle(
                        .secondary
                    )

                Spacer()
            }
            .frame(height: 58)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Composer

private extension TodayDatedView {

    var composer: some View {

        VStack(spacing: 0) {

            HStack(spacing: 18) {

                Text("+")
                    .font(
                        .system(size: 21)
                    )

                TextField(
                    "Add item",
                    text: $newItemText
                )
                .font(
                    .system(size: 18)
                )
                .submitLabel(.done)
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
                .system(size: 16)
            )
            .foregroundStyle(
                hasSelectedTime
                ? Color(
                    red: 0.25,
                    green: 0.48,
                    blue: 0.39
                )
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
                        ? Color(
                            red: 0.92,
                            green: 0.96,
                            blue: 0.94
                        )
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
                    .system(size: 16)
                )
                .foregroundStyle(
                    repeatEveryDay
                    ? Color(
                        red: 0.25,
                        green: 0.48,
                        blue: 0.39
                    )
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
                            ? Color(
                                red: 0.92,
                                green: 0.96,
                                blue: 0.94
                            )
                            : Color(
                                .systemGray6
                            )
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Item

private extension TodayDatedView {

    func addItem() {

        let trimmedText =
            newItemText.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard !trimmedText.isEmpty
        else {
            return
        }

        guard isToday
        else {
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
                    repeatEveryDay
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

            if hasSelectedTime {

                NotificationManager.requestAuthorization {
                    granted in

                    newItem.reminderEnabled =
                        granted

                    if granted {

                        NotificationManager.scheduleReminder(
                            for: newItem
                        )
                    }

                    try? modelContext.save()
                }
            }

            newItemText = ""
            repeatEveryDay = false
            selectedTime = Self.defaultTime
            hasSelectedTime = false
            isAddingItem = false
            showingTimePicker = false

        } catch {

            print(
                "Failed to save TodayItem: \(error)"
            )
        }
    }
}

// MARK: - Save

private extension TodayDatedView {

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

    NavigationStack {

        TodayDatedView()
    }
    .modelContainer(
        for: [
            TodayItem.self,
            ChecklistList.self,
            ChecklistListItem.self,
            Occurrence.self,
            OccurrenceItem.self
        ],
        inMemory: true
    )
}
