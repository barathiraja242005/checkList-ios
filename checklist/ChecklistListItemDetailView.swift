import SwiftUI
import SwiftData

struct ChecklistListItemDetailView: View {

    @Bindable var item: ChecklistListItem

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    @State private var showingTimePicker = false
    @State private var selectedTime = Date()

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            header
            content
            Spacer()
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .backSwipe()
        
        .onAppear {
            selectedTime =
                item.scheduledDate ?? Date()
        }
        .sheet(
            isPresented: $showingTimePicker
        ) {
            TimePickerView(
                itemName: item.text,
                selectedTime: $selectedTime,
                onClear: {
                    clearTime()
                },
                onDone: {
                    saveTime()
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

// MARK: - Header

private extension ChecklistListItemDetailView {

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
                            size: 13,
                            weight: .medium
                        )
                    )

                    Text("List")
                        .font(
                            .system(size: 17)
                        )
                }
                .foregroundStyle(
                    .secondary
                )
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

private extension ChecklistListItemDetailView {

    var content: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            Text(item.text)
                .font(
                    .system(
                        size: 29,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    .primary
                )
                .padding(.top, 12)
                .padding(.bottom, 28)

            dateRow
            timeRow
            reminderRow
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Date

private extension ChecklistListItemDetailView {

    var dateRow: some View {
        DatePicker(
            "Date",
            selection: dateBinding,
            displayedComponents: [.date]
        )
        .font(
            .system(size: 16)
        )
        .frame(height: 48)
        .overlay(
            Rectangle()
                .fill(
                    Color(.systemGray5)
                )
                .frame(height: 1),
            alignment: .bottom
        )
    }

    var dateBinding: Binding<Date> {
        Binding(
            get: {
                item.scheduledDate ?? Date()
            },
            set: { newDate in

                let calendar =
                    Calendar.current

                if let existingDate =
                    item.scheduledDate {

                    if item.hasScheduledTime {

                        item.scheduledDate =
                            calendar.date(
                                bySettingHour:
                                    calendar.component(
                                        .hour,
                                        from: existingDate
                                    ),
                                minute:
                                    calendar.component(
                                        .minute,
                                        from: existingDate
                                    ),
                                second: 0,
                                of: newDate
                            )

                    } else {

                        item.scheduledDate =
                            calendar.startOfDay(
                                for: newDate
                            )
                    }

                } else {

                    item.scheduledDate =
                        calendar.startOfDay(
                            for: newDate
                        )
                }

                saveChanges()

                if item.reminderEnabled {
                    NotificationManager.scheduleReminder(
                        for: item
                    )
                }
            }
        )
    }
}

// MARK: - Time

private extension ChecklistListItemDetailView {

    var timeRow: some View {
        Button {
            selectedTime =
                item.scheduledDate ?? Date()

            showingTimePicker = true
        } label: {

            HStack {

                Text("Time")
                    .font(
                        .system(size: 16)
                    )
                    .foregroundStyle(
                        .primary
                    )

                Spacer()

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
                        Color(
                            red: 0.20,
                            green: 0.48,
                            blue: 0.37
                        )
                    )

                } else {

                    Text("Set time")
                        .font(
                            .system(size: 16)
                        )
                        .foregroundStyle(
                            .secondary
                        )
                }
            }
            .frame(height: 48)
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

    func saveTime() {

        let calendar =
            Calendar.current

        let baseDate =
            item.scheduledDate ?? Date()

        guard let newDate =
            calendar.date(
                bySettingHour:
                    calendar.component(
                        .hour,
                        from: selectedTime
                    ),
                minute:
                    calendar.component(
                        .minute,
                        from: selectedTime
                    ),
                second: 0,
                of: baseDate
            )
        else {
            return
        }

        item.scheduledDate = newDate
        item.hasScheduledTime = true

        saveChanges()

        showingTimePicker = false

        if item.reminderEnabled {
            NotificationManager.scheduleReminder(
                for: item
            )
        }
    }

    func clearTime() {

        guard let scheduledDate =
            item.scheduledDate
        else {
            showingTimePicker = false
            return
        }

        let calendar =
            Calendar.current

        item.scheduledDate =
            calendar.startOfDay(
                for: scheduledDate
            )

        item.hasScheduledTime = false
        item.reminderEnabled = false

        NotificationManager.cancelReminder(
            for: item
        )

        saveChanges()

        showingTimePicker = false
    }
}

// MARK: - Reminder

private extension ChecklistListItemDetailView {

    var reminderRow: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                if item.reminderEnabled,
                   item.hasScheduledTime,
                   let scheduledDate =
                        item.scheduledDate {

                    Text(
                        "Remind me at "
                        + scheduledDate.formatted(
                            .dateTime
                                .hour()
                                .minute()
                        )
                    )
                    .font(
                        .system(size: 16)
                    )
                    .foregroundStyle(
                        .primary
                    )

                } else {

                    Text("Remind me")
                        .font(
                            .system(size: 16)
                        )
                        .foregroundStyle(
                            .primary
                        )
                }

                Text(
                    reminderDescription
                )
                .font(
                    .system(size: 12)
                )
                .foregroundStyle(
                    .secondary
                )
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
                Color(
                    red: 0.20,
                    green: 0.48,
                    blue: 0.37
                )
            )
            .disabled(
                !item.hasScheduledTime ||
                item.scheduledDate == nil
            )
        }
        .frame(minHeight: 58)
        .overlay(
            Rectangle()
                .fill(
                    Color(.systemGray5)
                )
                .frame(height: 1),
            alignment: .bottom
        )
    }

    var reminderDescription: String {

        if item.scheduledDate == nil {
            return "Set a date and time above to turn this on."
        }

        if !item.hasScheduledTime {
            return "Set a time above to turn this on."
        }

        return "A one-time notification at this time."
    }

    var reminderToggleBinding: Binding<Bool> {

        Binding(
            get: {
                item.reminderEnabled
            },
            set: { newValue in

                guard newValue else {

                    item.reminderEnabled = false

                    NotificationManager.cancelReminder(
                        for: item
                    )

                    saveChanges()

                    return
                }

                guard
                    item.scheduledDate != nil,
                    item.hasScheduledTime
                else {
                    return
                }

                NotificationManager.requestAuthorization {
                    granted in

                    item.reminderEnabled =
                        granted

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

// MARK: - Save

private extension ChecklistListItemDetailView {

    func saveChanges() {

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to save list item: \(error)"
            )
        }
    }
}

// MARK: - Preview

#Preview {

    let item = ChecklistListItem(
        text: "Buy groceries",
        scheduledDate: Date(),
        hasScheduledTime: false,
        reminderEnabled: false
    )

    NavigationStack {
        ChecklistListItemDetailView(
            item: item
        )
    }
    .modelContainer(
        for: [
            ChecklistList.self,
            ChecklistListItem.self
        ],
        inMemory: true
    )
}
