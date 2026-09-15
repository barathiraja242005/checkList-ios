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

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            header

            content

            Spacer()
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .backSwipe()
        .onAppear {
            selectedTime = item.remindAt ?? Date()
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
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.hidden)
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

// MARK: - Content

private extension ItemDetailView {

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
                .foregroundStyle(.primary)
                .padding(.top, 12)
                .padding(.bottom, 28)

            timeRow
            everyDayRow
            reminderRow
            removeItemRow
        }
        .padding(.horizontal, 24)
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
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)

                Spacer()

                if let remindAt = item.remindAt {

                    Text(
                        remindAt,
                        format: .dateTime
                            .hour()
                            .minute()
                    )
                    .font(.system(size: 16))
                    .foregroundStyle(
                        Color(
                            red: 0.20,
                            green: 0.48,
                            blue: 0.37
                        )
                    )

                } else {

                    Text("Set time")
                        .font(.system(size: 16))
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
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)

                Text(
                    "Off means it only sits on today's list."
                )
                .font(.system(size: 12))
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
                Color(
                    red: 0.20,
                    green: 0.48,
                    blue: 0.37
                )
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

            showingRemoveSheet = true

        } label: {

            HStack {

                Text("Remove item")
                    .font(.system(size: 16))
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

// MARK: - Just Today

private extension ItemDetailView {

    func removeJustToday() {

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
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)

                } else {

                    Text("Remind me")
                        .font(.system(size: 16))
                        .foregroundStyle(.primary)
                }

                Text(
                    item.remindAt == nil
                        ? "Set a time above to turn this on."
                        : item.repeatsDaily
                            ? "A notification every day at this time."
                            : "A one-time notification at this time."
                )
                .font(.system(size: 12))
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
                Color(
                    red: 0.20,
                    green: 0.48,
                    blue: 0.37
                )
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
