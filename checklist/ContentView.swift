import SwiftUI
import SwiftData

enum AppRoute: Hashable {
    case newList
    case listDetail(UUID)
}

struct ContentView: View {

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - Navigation

    @State private var navigationPath = NavigationPath()

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

    // MARK: - Lists

    @Query(
        sort: [
            SortDescriptor(\ChecklistList.title)
        ]
    )
    private var lists: [ChecklistList]

    // MARK: - Add Item State

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

        NavigationStack(
            path: $navigationPath
        ) {

            ZStack(
                alignment: .bottomTrailing
            ) {

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 0
                    ) {

                        header

                        todayItemsSection

                        listsSection
                    }
                    .padding(.horizontal, 34)
                    .padding(.top, 28)
                    .padding(.bottom, 110)
                }
                .scrollIndicators(.hidden)

                floatingAddButton
            }
            .background(Color.white)

            // MARK: - Navigation Destinations

            .navigationDestination(
                for: AppRoute.self
            ) { route in

                switch route {

                case .newList:

                    NewListView(
                        navigationPath: $navigationPath
                    )

                case .listDetail(let listID):

                    if let list =
                        lists.first(
                            where: {
                                $0.id == listID
                            }
                        ) {

                        ListDetailView(
                            list: list
                        )

                    } else {

                        Text("List not found")
                    }
                }
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

        let today =
            Calendar.current.startOfDay(
                for: Date()
            )

        return todayItems.filter { item in

            guard let skippedDate =
                    item.skippedDate
            else {
                return true
            }

            return !Calendar.current.isDate(
                skippedDate,
                inSameDayAs: today
            )
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
                            size: 29,
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
                            size: 11,
                            weight: .semibold
                        )
                    )
                }
                .font(
                    .system(size: 17)
                )
                .foregroundStyle(
                    .secondary
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
                .frame(height: 38)

            ForEach(
                visibleTodayItems
            ) { item in

                TodayItemRow(
                    item: item
                )
                .frame(height: 59)
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
                scheduledTodayChecklistItems
            ) { item in

                scheduledChecklistItemRow(
                    item
                )
            }

            if !overdueChecklistItems.isEmpty {

                overdueSection
            }

            if isAddingItem {

                addItemComposer

            } else {

                addItemRow
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
                .foregroundStyle(
                    .secondary
                )
                .fixedSize()
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

// MARK: - Overdue

private extension ContentView {

    var overdueSection: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            Text("Overdue")
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .secondary
                )
                .padding(.top, 24)
                .padding(.bottom, 10)

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
            spacing: 6
        ) {

            HStack(
                spacing: 16
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
                        .system(size: 18)
                    )
                    .foregroundStyle(
                        .primary
                    )
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
                                .day()
                                .month(.abbreviated)
                                .year()
                        )
                    )
                    .font(
                        .system(size: 13)
                    )
                    .foregroundStyle(
                        .secondary
                    )
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

// MARK: - Add Item Composer

private extension ContentView {

    var addItemComposer: some View {

        VStack(spacing: 0) {

            HStack(spacing: 18) {

                Text("+")
                    .font(
                        .system(size: 21)
                    )
                    .foregroundStyle(
                        .secondary
                    )

                TextField(
                    "Add item",
                    text: $newItemText
                )
                .font(
                    .system(size: 18)
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

// MARK: - Add Today Item

private extension ContentView {

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

// MARK: - Lists

private extension ContentView {

    var listsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            Text("Lists")
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .secondary
                )
                .padding(.top, 25)
                .padding(.bottom, 18)

            ForEach(
                lists
            ) { list in

                ChecklistListRow(
                    list: list
                )
            }
        }
    }
}

// MARK: - Floating Add Button

private extension ContentView {

    var floatingAddButton: some View {

        Button {

            navigationPath.append(
                AppRoute.newList
            )

        } label: {

            Image(
                systemName: "plus"
            )
            .font(
                .system(
                    size: 25,
                    weight: .medium
                )
            )
            .foregroundStyle(.white)
            .frame(
                width: 64,
                height: 64
            )
            .background(
                Color(
                    red: 0.12,
                    green: 0.42,
                    blue: 0.31
                )
            )
            .clipShape(
                Circle()
            )
        }
        .buttonStyle(.plain)
        .padding(.trailing, 24)
        .padding(.bottom, 25)
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
