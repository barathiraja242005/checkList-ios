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
                    saveChanges()
                },
                onDone: {
                    item.remindAt = selectedTime
                    saveChanges()
                }
            )
            .presentationDetents([.height(490)])
            .presentationDragIndicator(.hidden)
        }
        .sheet(
            isPresented: $showingRemoveSheet
        ) {
            removeItemSheet
                .presentationDetents([.height(390)])
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
                            removeFutureOccurrences()
                            saveChanges()
                        }
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

// MARK: - Remove Item

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

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 42, height: 5)
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )
                .padding(.top, 12)
                .padding(.bottom, 18)

            Text("Remove \(item.text)")
                .font(
                    .system(
                        size: 21,
                        weight: .bold
                    )
                )

            Text(
                "Earlier days keep their record either way."
            )
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
            .padding(.top, 4)
            .padding(.bottom, 20)

            Button {

                removeJustToday()

            } label: {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Just today")
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)

                    Text(
                        "Stays on your list from tomorrow. Use this when you're skipping a day."
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            Divider()

            Button {

                removeTodayAndFuture()

            } label: {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Today and future days")
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)

                    Text(
                        "Removes it from your routine for good."
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {

                showingRemoveSheet = false

            } label: {

                Text("Cancel")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 10)
        .background(Color.white)
    }
}

// MARK: - Just Today

private extension ItemDetailView {

    func removeJustToday() {

        let calendar = Calendar.current
        let today = calendar.startOfDay(
            for: Date()
        )

        if item.repeatsDaily {

            item.skippedDate = today

            saveChanges()

        } else {

            modelContext.delete(item)

            do {

                try modelContext.save()

            } catch {

                print(
                    "Failed to remove item: \(error)"
                )
            }
        }

        showingRemoveSheet = false
        dismiss()
    }
}

// MARK: - Today and Future

private extension ItemDetailView {

    func removeTodayAndFuture() {

        removeFutureOccurrences()

        modelContext.delete(item)

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to permanently remove item: \(error)"
            )
        }

        showingRemoveSheet = false
        dismiss()
    }
}

// MARK: - Remove Future Occurrences

private extension ItemDetailView {

    func removeFutureOccurrences() {

        let calendar = Calendar.current

        let today =
            calendar.startOfDay(
                for: Date()
            )

        for occurrence in occurrences {

            let occurrenceDate =
                calendar.startOfDay(
                    for: occurrence.periodDate
                )

            guard occurrenceDate > today
            else {
                continue
            }

            let matchingItems =
                occurrence.items.filter {
                    occurrenceItem in

                    occurrenceItem.sourceItemID == item.id
                }

            for occurrenceItem in matchingItems {

                modelContext.delete(
                    occurrenceItem
                )
            }

            occurrence.items.removeAll {
                occurrenceItem in

                occurrenceItem.sourceItemID == item.id
            }

            if occurrence.items.isEmpty {

                modelContext.delete(
                    occurrence
                )
            }
        }
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

                if let remindAt = item.remindAt {

                    Text(
                        "Remind me at "
                        + remindAt.formatted(
                            .dateTime
                                .hour()
                                .minute()
                        )
                    )
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                } else {

                    Text("Remind me")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }

                Text(
                    "A notification, with a button to tick it off without opening the app."
                )
                .font(.system(size: 12))
                .foregroundStyle(
                    Color.secondary.opacity(0.65)
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }

            Spacer()

            Text("Plus")
                .font(
                    .system(
                        size: 11,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    Color(
                        red: 0.20,
                        green: 0.48,
                        blue: 0.37
                    )
                )
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    Color(
                        red: 0.20,
                        green: 0.48,
                        blue: 0.37
                    )
                    .opacity(0.08)
                )
                .clipShape(Capsule())
        }
        .frame(minHeight: 58)
        .opacity(0.55)
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1),
            alignment: .bottom
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
