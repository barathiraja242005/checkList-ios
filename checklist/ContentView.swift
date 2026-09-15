import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query(
        sort: [
            SortDescriptor(\TodayItem.position)
        ]
    )
    private var todayItems: [TodayItem]

    @Query(
        sort: [
            SortDescriptor(\ChecklistList.title)
        ]
    )
    private var lists: [ChecklistList]

    @State private var isAddingItem = false
    @State private var newItemText = ""
    @State private var repeatEveryDay = false

    @State private var selectedTime: Date =
        Self.defaultTime

    @State private var hasSelectedTime = false
    @State private var showingTimePicker = false

    @FocusState
    private var isNewItemFieldFocused: Bool

    private static var defaultTime: Date {

        Calendar.current.date(
            bySettingHour: 21,
            minute: 30,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    var body: some View {

        NavigationStack {

            ZStack(alignment: .bottomTrailing) {

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
        }
        .sheet(
            isPresented: $showingTimePicker
        ) {

            TimePickerView(
                itemName:
                    newItemText.isEmpty
                    ? "New item"
                    : newItemText,

                selectedTime:
                    $selectedTime,

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

    // MARK: - Visible Today Items

    private var visibleTodayItems: [TodayItem] {

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

    // MARK: - Header

    private var header: some View {

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
                    .foregroundStyle(.primary)

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
                        "\(completedCount) of \(visibleTodayItems.count) done"
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
                .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var completedCount: Int {

        visibleTodayItems.filter {
            $0.checked
        }.count
    }

    // MARK: - Today Items

    private var todayItemsSection: some View {

        VStack(spacing: 0) {

            Spacer()
                .frame(height: 38)

            List {

                ForEach(
                    visibleTodayItems
                ) { item in

                    TodayItemRow(
                        item: item
                    )
                    .listRowInsets(
                        EdgeInsets()
                    )
                    .listRowSeparatorTint(
                        Color(.systemGray5)
                    )
                    .alignmentGuide(
                        .listRowSeparatorLeading
                    ) { _ in
                        0
                    }
                    .alignmentGuide(
                        .listRowSeparatorTrailing
                    ) { $0.width }
                    .listRowBackground(
                        Color.clear
                    )
                }
                .onMove(
                    perform: moveItems
                )
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .frame(
                height:
                    CGFloat(
                        visibleTodayItems.count
                    ) * 59
            )

            if isAddingItem {

                addItemComposer

            } else {

                addItemRow
            }
        }
    }

    private func moveItems(
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

    // MARK: - Add Item Row

    private var addItemRow: some View {

        Button {

            isAddingItem = true
            newItemText = ""
            repeatEveryDay = false
            selectedTime = Self.defaultTime
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

    // MARK: - Add Item Composer

    private var addItemComposer: some View {

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

        // TOP DIVIDER TEMPORARILY DISABLED
        // This is a diagnostic test to identify
        // which divider is creating the duplicate line.

        /*
        .overlay(
            alignment: .top
        ) {

            Rectangle()
                .fill(
                    Color(.systemGray5)
                )
                .frame(height: 1)
        }
        */

        // BOTTOM DIVIDER REMAINS

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

    // MARK: - Time Chip

    private var timeChip: some View {

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

    // MARK: - Repeat Chip

    private var repeatChip: some View {

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

    // MARK: - Add Item

    private func addItem() {

        let trimmedText =
            newItemText.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard !trimmedText.isEmpty
        else {

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
    }

    // MARK: - Lists

    private var listsSection: some View {

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

            ForEach(lists) { list in

                ChecklistListRow(
                    list: list
                )
            }
        }
    }

    // MARK: - Floating Add Button

    private var floatingAddButton: some View {

        NavigationLink {

            NewListView()

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

#Preview {

    ContentView()
        .modelContainer(
            for: [
                TodayItem.self,
                ChecklistList.self
            ],
            inMemory: true
        )
}
