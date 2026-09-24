import SwiftUI
import SwiftData

struct ItemDetailView: View {

    @Bindable var item: TodayItem

    // What the back button says, so it names the screen actually behind it.
    var backTitle: String = "Today"

    // Opened from Add reminder: the task is a blank draft, so it starts with
    // Remind me already chosen and is thrown away again if it never gets a
    // name.
    var isNewReminder: Bool = false

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var occurrences: [Occurrence]

    @State private var showingTimePicker = false
    @State private var selectedTime = Date()
    @State private var showingRemoveSheet = false
    @State private var showingDatePicker = false

    // Kept so an emptied name can be restored rather than saved blank.
    @State private var nameBeforeEditing = ""

    // onDisappear commits the name, which must not run against an item the
    // removal flow has already deleted.
    @State private var isRemoving = false

    @FocusState private var isNameFocused: Bool

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            header

            ScrollView {

                content
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .pageBackground()
        .navigationBarBackButtonHidden(true)
        .backSwipe()
        .onAppear {

            selectedTime = item.remindAt ?? Date()
            nameBeforeEditing = item.text

            isNameFocused = true
        }
        .onDisappear {

            commitName()

            discardEmptyDraft()
        }
        .sheet(
            isPresented: $showingTimePicker
        ) {

            TimePickerView(
                itemName: item.text,
                selectedTime: $selectedTime,
                onClear: {

                    item.remindAt = nil
                    item.reminderEnabled = false

                    NotificationManager.cancelReminder(
                        for: item
                    )

                    saveChanges()
                },
                onDone: {

                    item.remindAt = selectedTime

                    scheduleIfNewReminder()

                    if item.reminderEnabled {

                        NotificationManager.scheduleReminder(
                            for: item
                        )

                        saveChanges()

                    } else {

                        NotificationManager.requestAuthorization { granted in

                            item.reminderEnabled = granted

                            if granted {

                                NotificationManager.scheduleReminder(
                                    for: item
                                )
                            }

                            saveChanges()
                        }
                    }
                }
            )
            .presentationDetents([.height(490)])
            .presentationDragIndicator(.hidden)
        }
        .sheet(
            isPresented: $showingRemoveSheet
        ) {
            removeItemSheet
                // 290 to fit the redesigned sheet's card layout.
                .presentationDetents([.height(290)])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Header

private extension ItemDetailView {

    var header: some View {

        HStack {

            if isNewReminder {

                Button {
                    cancelDraft()
                } label: {

                    Text("Cancel")
                        .font(
                            .system(size: 16)
                        )
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    saveDraft()
                } label: {

                    Text("Save")
                        .font(
                            .system(
                                size: 16,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            hasName
                                ? Color.accentGreen
                                : Color.secondary
                        )
                }
                .buttonStyle(.plain)
                // A reminder with no name is not one, so there is nothing
                // to save until it has been given one.
                .disabled(!hasName)

            } else {

                Button {
                    dismiss()
                } label: {

                    HStack(spacing: 4) {

                        Image(
                            systemName: "chevron.left"
                        )
                        .font(
                            .system(
                                size: 12,
                                weight: .medium
                            )
                        )

                        Text(backTitle)
                            .font(
                                .system(size: 16)
                            )
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }
}

// MARK: - Content

private extension ItemDetailView {

    var content: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            TextField(
                "Item name",
                text: $item.text,
                axis: .vertical
            )
            .font(
                .system(
                    size: 26,
                    weight: .bold
                )
            )
            .foregroundStyle(.primary)
            .textFieldStyle(.plain)
            .focused($isNameFocused)
            .submitLabel(.done)
            .onSubmit {
                commitName()
            }
            // A vertical-axis field takes Return as a line break rather than
            // a submit, so the newline is caught here and turned into the
            // end of editing: keyboard away, page stays put.
            .onChange(of: item.text) { _, newValue in

                guard newValue.contains("\n")
                else {
                    return
                }

                item.text = newValue.replacingOccurrences(
                    of: "\n",
                    with: ""
                )

                commitName()
            }
            .padding(.top, 12)
            .padding(.bottom, 28)

            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                dateRow
                timeRow
                recurrenceRow
                reminderRow

                // A draft is cancelled from the header; there is nothing
                // yet to remove.
                if !isNewReminder {

                    removeItemRow
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Date

private extension ItemDetailView {

    // A repeating task is regenerated each day, so a fixed date would be
    // meaningless for it; the row only applies to one-off tasks.
    var dateRow: some View {

        VStack(spacing: 0) {

            Button {

                // Without this the keyboard stays up over the calendar that
                // is about to open, and the date looks unselectable.
                if isNameFocused {
                    commitName()
                }

                // The calendar opens with today highlighted whether or not a
                // date is set, and tapping the day already highlighted is not
                // a change iOS reports — so today would never take. Opening
                // on an undated task settles it on today up front: the
                // highlight is then telling the truth, and any other day is a
                // real change.
                if !showingDatePicker,
                    item.scheduledDate == nil {

                    setDate(
                        Calendar.current.startOfDay(for: Date())
                    )
                }

                withAnimation(
                    .easeInOut(duration: 0.2)
                ) {
                    showingDatePicker.toggle()
                }

            } label: {

                HStack {

                    Text("Date")
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)

                    Spacer()

                    if let scheduledDate = item.scheduledDate {

                        Text(
                            scheduledDate,
                            format:
                                .dateTime
                                .day()
                                .month(.abbreviated)
                                .year()
                        )
                        .font(.system(size: 15))
                        .foregroundStyle(Color.accentGreen)

                    } else {

                        Text("No date")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 48)
                .overlay(
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 1),
                    alignment: .bottom
                )
            }
            .buttonStyle(.plain)
            .disabled(item.repeatsDaily)
            .opacity(
                item.repeatsDaily
                ? 0.5
                : 1
            )

            if showingDatePicker {

                VStack(spacing: 0) {

                    DatePicker(
                        "",
                        selection: scheduledDateBinding,
                        in: earliestSelectableDate...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(Color.accentGreen)

                    // Clearing the date leaves the task on Today
                    // indefinitely, so it never turns up as overdue.
                    HStack {

                        Button {

                            clearDate()

                        } label: {

                            Text("Clear date")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.deleteRed)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .disabled(item.scheduledDate == nil)
                        .opacity(
                            item.scheduledDate == nil
                            ? 0.4
                            : 1
                        )

                        Spacer()

                        // Re-tapping the day already chosen is not a change
                        // iOS reports, so there is always a plain way to
                        // close rather than only the implicit one.
                        Button {

                            withAnimation(
                                .easeInOut(duration: 0.2)
                            ) {
                                showingDatePicker = false
                            }

                        } label: {

                            Text("Done")
                                .font(
                                    .system(
                                        size: 15,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(Color.accentGreen)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
                .overlay(
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 1),
                    alignment: .bottom
                )
            }
        }
    }

    // Nothing earlier than today can be chosen. A task already sitting on a
    // past date keeps that date as the floor, so opening its picker shows
    // where it actually is rather than silently dragging it forward. Same
    // rule the list-item screen already used.
    var earliestSelectableDate: Date {

        let calendar = Calendar.current

        let startOfToday = calendar.startOfDay(
            for: Date()
        )

        guard let scheduledDate = item.scheduledDate
        else {
            return startOfToday
        }

        return min(
            calendar.startOfDay(
                for: scheduledDate
            ),
            startOfToday
        )
    }

    var scheduledDateBinding: Binding<Date> {

        Binding(
            get: {
                item.scheduledDate ?? Date()
            },
            set: { newDate in

                setDate(newDate)

                // The choice is made, so the calendar folds away rather than
                // sitting open over the rest of the screen.
                withAnimation(
                    .easeInOut(duration: 0.2)
                ) {
                    showingDatePicker = false
                }
            }
        )
    }

    func setDate(
        _ newDate: Date
    ) {

        item.scheduledDate =
            Calendar.current.startOfDay(
                for: newDate
            )

        // A date on its own still needs an hour to fire at.
        if item.remindAt == nil {

            item.remindAt = Self.defaultReminderTime
        }

        scheduleIfNewReminder()

        saveChanges()
    }

    func clearDate() {

        item.scheduledDate = nil

        withAnimation(
            .easeInOut(duration: 0.2)
        ) {
            showingDatePicker = false
        }

        saveChanges()
    }
}

// MARK: - Time

private extension ItemDetailView {

    var timeRow: some View {

        Button {

            if isNameFocused {
                commitName()
            }

            selectedTime =
                item.remindAt ?? Date()

            showingTimePicker = true

        } label: {

            HStack {

                Text("Time")
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)

                Spacer()

                if let remindAt = item.remindAt {

                    Text(
                        remindAt,
                        format: .dateTime
                            .hour()
                            .minute()
                    )
                    .font(.system(size: 15))
                    .foregroundStyle(
                        Color.accentGreen
                    )

                } else {

                    Text("Set time")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 48)
            .overlay(
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recurrence

private extension ItemDetailView {

    var recurrenceRow: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text("Repeat")
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)

                Text(item.recurrence.summary)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 12)

            Menu {

                ForEach(
                    Recurrence.allCases
                ) { option in

                    Button {

                        apply(option)

                    } label: {

                        if option == item.recurrence {

                            Label(
                                option.label,
                                systemImage: "checkmark"
                            )

                        } else {

                            Text(option.label)
                        }
                    }
                }

            } label: {

                HStack(spacing: 4) {

                    ZStack(alignment: .trailing) {

                        // Every option, laid out invisibly, so the slot is
                        // always as wide as the longest of them. Without it
                        // the row resizes when the choice changes and the
                        // new text is clipped until the animation settles.
                        ForEach(
                            Recurrence.allCases
                        ) { option in

                            Text(option.label)
                                .font(.system(size: 15))
                                .hidden()
                        }

                        Text(item.recurrence.label)
                            .font(.system(size: 15))
                            .lineLimit(1)
                    }

                    Image(
                        systemName: "chevron.up.chevron.down"
                    )
                    .font(
                        .system(size: 11, weight: .semibold)
                    )
                }
                // Never squeezed into an ellipsis by the label beside it.
                .fixedSize()
                .layoutPriority(1)
                .foregroundStyle(
                    item.recurrence == .none
                        ? Color.secondary
                        : Color.accentGreen
                )
            }
        }
        .frame(minHeight: 60)
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    func apply(
        _ recurrence: Recurrence
    ) {

        if isNameFocused {
            commitName()
        }

        let previous = item.recurrence

        guard recurrence != previous
        else {
            return
        }

        // Leaving Daily behind means the days it had already booked ahead are
        // no longer its to keep.
        if previous == .daily {

            TodayItemRemoval.removeFutureOccurrences(
                for: item,
                occurrences: occurrences,
                context: modelContext
            )

            item.completedThrough = nil
        }

        item.recurrence = recurrence

        // Every interval but daily is anchored to a date, so one is needed
        // before the repeat means anything.
        if recurrence.advancesItsOwnDate,
            item.scheduledDate == nil {

            item.scheduledDate =
                Calendar.current.startOfDay(for: Date())
        }

        saveChanges()

        NotificationManager.scheduleReminder(
            for: item
        )
    }
}

// MARK: - cItem

private extension ItemDetailView {

    var removeItemRow: some View {

        Button {

            if isNameFocused {
                commitName()
            }

            // Dropping one occurrence versus the whole routine is only a
            // real choice for something that repeats; a one-off just goes.
            if item.recurrence != .none {
                showingRemoveSheet = true
            } else {
                deleteOneTimeItem()
            }

        } label: {

            HStack {

                Text("Remove item")
                    .font(.system(size: 15))
                    .foregroundStyle(.red)

                Spacer()
            }
            .frame(height: 58)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Remove Item Sheet

private extension ItemDetailView {

    var removeItemSheet: some View {

        RemoveItemSheet(
            itemText: item.text,
            recurrence: item.recurrence,
            onJustToday: {
                removeJustToday()
            },
            onTodayAndFuture: {
                removeTodayAndFuture()
            },
            onCancel: {
                showingRemoveSheet = false
            }
        )
    }
}

// MARK: - One-Time Item

private extension ItemDetailView {

    func deleteOneTimeItem() {

        isRemoving = true

        TodayItemRemoval.removeTodayAndFuture(
            item,
            occurrences: occurrences,
            context: modelContext
        )

        dismiss()
    }
}

// MARK: - Just Today

private extension ItemDetailView {

    func removeJustToday() {

        isRemoving = true

        TodayItemRemoval.removeJustToday(
            item,
            context: modelContext
        )

        showingRemoveSheet = false
        dismiss()
    }
}

// MARK: - Today and Future

private extension ItemDetailView {

    func removeTodayAndFuture() {

        isRemoving = true

        TodayItemRemoval.removeTodayAndFuture(
            item,
            occurrences: occurrences,
            context: modelContext
        )

        showingRemoveSheet = false
        dismiss()
    }
}

// MARK: - Reminder

private extension ItemDetailView {

    var reminderRow: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                if item.reminderEnabled,
                    let remindAt = item.remindAt {

                    Text(
                        "Remind me at "
                        + remindAt.formatted(
                            .dateTime
                                .hour()
                                .minute()
                        )
                    )
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)

                } else {

                    Text("Remind me")
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                }

                Text(reminderSummary)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }

            Spacer()

            Toggle(
                "",
                isOn: hasSchedule
                    ? reminderToggleBinding
                    : .constant(isNewReminder)
            )
            .disabled(!hasSchedule)
            .labelsHidden()
            .tint(
                Color.accentGreen
            )
            .disabled(item.remindAt == nil)
        }
        .frame(minHeight: 58)
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // A reminder needs a date or a time before it can fire, so until one of
    // them is set the switch is shown but does nothing. On a new reminder it
    // sits on, since turning it on is the whole point of the screen.
    var hasSchedule: Bool {

        item.remindAt != nil || item.scheduledDate != nil
    }

    var reminderSummary: String {

        guard hasSchedule
        else {
            return "Set a date or time to turn this on."
        }

        guard item.remindAt != nil
        else {
            return "Set a time, or this fires at 10:00."
        }

        switch item.recurrence {

        case .none:
            return "A one-time notification at this time."

        case .daily, .weekly, .biweekly, .monthly:
            return "A notification \(item.recurrence.label.lowercased()) at this time."
        }
    }

    var reminderToggleBinding: Binding<Bool> {

        Binding(
            get: {
                item.reminderEnabled
            },
            set: { newValue in

                if isNameFocused {
                    commitName()
                }

                guard newValue
                else {

                    item.reminderEnabled = false

                    NotificationManager.cancelReminder(
                        for: item
                    )

                    saveChanges()
                    return
                }

                NotificationManager.requestAuthorization { granted in

                    item.reminderEnabled = granted

                    if granted {

                        NotificationManager.scheduleReminder(
                            for: item
                        )
                    }

                    saveChanges()
                }
            }
        )
    }
}

// MARK: - New Reminder

private extension ItemDetailView {

    // A date with no time of its own fires mid-morning rather than at
    // whatever o'clock the screen happened to be opened.
    static var defaultReminderTime: Date {

        Calendar.current.date(
            bySettingHour: 10,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    // On a draft the switch is already showing as on, so the moment there is
    // something to fire on it is made true rather than left as decoration.
    func scheduleIfNewReminder() {

        guard
            isNewReminder,
            !item.reminderEnabled,
            hasSchedule
        else {
            return
        }

        NotificationManager.requestAuthorization { granted in

            item.reminderEnabled = granted

            if granted {

                NotificationManager.scheduleReminder(
                    for: item
                )
            }

            saveChanges()
        }
    }

    var hasName: Bool {

        !item.text.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    func cancelDraft() {

        isRemoving = true
        isNameFocused = false

        NotificationManager.cancelReminder(for: item)

        modelContext.delete(item)

        saveChanges()

        dismiss()
    }

    func saveDraft() {

        commitName()

        if item.reminderEnabled {

            NotificationManager.scheduleReminder(
                for: item
            )
        }

        saveChanges()

        dismiss()
    }

    // A draft that never got a name is not a reminder, so it goes rather than
    // leaving a nameless row behind.
    func discardEmptyDraft() {

        guard
            isNewReminder,
            !isRemoving,
            item.text.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        else {
            return
        }

        NotificationManager.cancelReminder(for: item)

        modelContext.delete(item)

        saveChanges()
    }
}

// MARK: - Name

private extension ItemDetailView {

    func commitName() {

        guard !isRemoving
        else {
            return
        }

        let trimmed = item.text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // A blank name would leave an unidentifiable row, so fall back to
        // whatever it was called before editing started.
        item.text =
            trimmed.isEmpty
            ? nameBeforeEditing
            : trimmed

        isNameFocused = false

        saveChanges()
    }
}

// MARK: - Save

private extension ItemDetailView {

    func saveChanges() {

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to save item: \(error)"
            )
        }
    }
}

// MARK: - Preview

#Preview {

    let item = TodayItem(
        text: "Evening tablet",
        remindAt: Calendar.current.date(
            bySettingHour: 21,
            minute: 30,
            second: 0,
            of: Date()
        ),
        repeatsDaily: true
    )

    NavigationStack {

        ItemDetailView(
            item: item
        )
    }
    .modelContainer(
        for: [
            TodayItem.self,
            Occurrence.self,
            OccurrenceItem.self
        ],
        inMemory: true
    )
}
