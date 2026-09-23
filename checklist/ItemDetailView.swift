import SwiftUI
import SwiftData

struct ItemDetailView: View {

    @Bindable var item: TodayItem

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

            content

            Spacer()
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

                    Text("Today")
                        .font(
                            .system(size: 16)
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
                everyDayRow
                reminderRow
                removeItemRow
            }
            // Tapping any of these finishes the name edit at the same time,
            // so the keyboard is gone before a picker opens instead of
            // needing a tap of its own to dismiss.
            .simultaneousGesture(
                TapGesture()
                    .onEnded {

                        guard isNameFocused
                        else {
                            return
                        }

                        commitName()
                    }
            )
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
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(Color.accentGreen)

                    // Clearing the date leaves the task on Today
                    // indefinitely, so it never turns up as overdue.
                    Button {

                        clearDate()

                    } label: {

                        Text("Clear date")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.deleteRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(item.scheduledDate == nil)
                    .opacity(
                        item.scheduledDate == nil
                        ? 0.4
                        : 1
                    )
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

    var scheduledDateBinding: Binding<Date> {

        Binding(
            get: {
                item.scheduledDate ?? Date()
            },
            set: { newDate in

                item.scheduledDate =
                    Calendar.current.startOfDay(
                        for: newDate
                    )

                saveChanges()
            }
        )
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

// MARK: - Every Day

private extension ItemDetailView {

    var everyDayRow: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text("Every day")
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)

                Text(
                    "Off means it only sits on today's list."
                )
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle(
                "",
                isOn: Binding(
                    get: {
                        item.repeatsDaily
                    },
                    set: { newValue in

                        if newValue {

                            item.repeatsDaily = true
                            saveChanges()

                        } else {

                            item.repeatsDaily = false

                            TodayItemRemoval.removeFutureOccurrences(
                                for: item,
                                occurrences: occurrences,
                                context: modelContext
                            )

                            saveChanges()
                        }

                        NotificationManager.scheduleReminder(
                            for: item
                        )
                    }
                )
            )
            .labelsHidden()
            .tint(
                Color.accentGreen
            )
        }
        .frame(minHeight: 60)
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - cItem

private extension ItemDetailView {

    var removeItemRow: some View {

        Button {

            // "Just today" vs "future days" is only a real choice for a
            // repeating item; a one-off just goes.
            if item.repeatsDaily {
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

                Text(
                    item.remindAt == nil
                        ? "Set a time above to turn this on."
                        : item.repeatsDaily
                            ? "A notification every day at this time."
                            : "A one-time notification at this time."
                )
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
                isOn: reminderToggleBinding
            )
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

    var reminderToggleBinding: Binding<Bool> {

        Binding(
            get: {
                item.reminderEnabled
            },
            set: { newValue in

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
