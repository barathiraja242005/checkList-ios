import SwiftUI
import AudioToolbox

struct TimePickerView: View {

    let itemName: String

    @Binding var selectedTime: Date

    let onClear: () -> Void
    let onDone: () -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var selectedHour: Int
    @State private var selectedMinute: Int

    private let hours = Array(0...23)

    private let minutes = Array(
        stride(
            from: 0,
            through: 55,
            by: 5
        )
    )

    init(
        itemName: String,
        selectedTime: Binding<Date>,
        onClear: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) {
        self.itemName = itemName
        self._selectedTime = selectedTime
        self.onClear = onClear
        self.onDone = onDone

        let calendar = Calendar.current

        let hour = calendar.component(
            .hour,
            from: selectedTime.wrappedValue
        )

        let minute = calendar.component(
            .minute,
            from: selectedTime.wrappedValue
        )

        _selectedHour = State(
            initialValue: hour
        )

        let roundedMinute =
            Int(
                (Double(minute) / 5.0)
                    .rounded()
            ) * 5

        _selectedMinute = State(
            initialValue: min(
                max(roundedMinute, 0),
                55
            )
        )
    }

    var body: some View {

        VStack(spacing: 0) {

            dragIndicator

            titleSection

            timePicker

            Divider()

            bottomBar
        }
        .background(Color(.systemBackground))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
    }
}

// MARK: - Drag Indicator

private extension TimePickerView {

    var dragIndicator: some View {

        Capsule()
            .fill(Color(.systemGray4))
            .frame(
                width: 42,
                height: 5
            )
            .padding(.top, 12)
            .padding(.bottom, 16)
    }
}

// MARK: - Title

private extension TimePickerView {

    var titleSection: some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            Text(
                "Time for “\(itemName)”"
            )
            .font(
                .system(
                    size: 21,
                    weight: .bold
                )
            )
            .foregroundStyle(.primary)

            Text(
                "Times order your list. They don't send anything yet."
            )
            .font(.system(size: 16))
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
        .padding(.horizontal, 26)
        .padding(.bottom, 12)
    }
}

// MARK: - Time Picker

private extension TimePickerView {

    var timePicker: some View {

        ZStack {

            // Rounded selection background
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(
                Color(
                    red: 0.95,
                    green: 0.95,
                    blue: 0.94
                )
            )
            .frame(
                height: 56
            )
            .padding(.horizontal, 26)

            HStack(
                alignment: .center,
                spacing: 0
            ) {

                hourPicker

                Text(":")
                    .font(
                        .system(
                            size: 24,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.primary)
                    .frame(width: 22)

                minutePicker
            }
        }
        .frame(height: 250)
    }

    var hourPicker: some View {

        Picker(
            "Hour",
            selection: $selectedHour
        ) {

            ForEach(
                hours,
                id: \.self
            ) { hour in

                Text(
                    String(
                        format: "%02d",
                        hour
                    )
                )
                .font(
                    .system(
                        size: 24,
                        weight: .regular
                    )
                )
                .tag(hour)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 115)
        .clipped()
        .onChange(
            of: selectedHour
        ) { _, _ in
            playPickerFeedback()
        }
    }

    var minutePicker: some View {

        Picker(
            "Minute",
            selection: $selectedMinute
        ) {

            ForEach(
                minutes,
                id: \.self
            ) { minute in

                Text(
                    String(
                        format: "%02d",
                        minute
                    )
                )
                .font(
                    .system(
                        size: 24,
                        weight: .regular
                    )
                )
                .tag(minute)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 115)
        .clipped()
        .onChange(
            of: selectedMinute
        ) { _, _ in
            playPickerFeedback()
        }
    }
}

// MARK: - Picker Feedback

private extension TimePickerView {

    func playPickerFeedback() {

        let haptic =
            UISelectionFeedbackGenerator()

        haptic.selectionChanged()

        // Small iOS system click sound.
        AudioServicesPlaySystemSound(1104)
    }
}

// MARK: - Bottom Bar

private extension TimePickerView {

    var bottomBar: some View {

        HStack {

            Button {

                onClear()
                dismiss()

            } label: {

                Text("Clear")
                    .font(
                        .system(
                            size: 18,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {

                saveSelectedTime()

                onDone()

                dismiss()

            } label: {

                Text("Done")
                    .font(
                        .system(
                            size: 18,
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
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .frame(height: 78)
    }
}

// MARK: - Save Time

private extension TimePickerView {

    func saveSelectedTime() {

        let calendar = Calendar.current

        var components =
            calendar.dateComponents(
                [
                    .year,
                    .month,
                    .day
                ],
                from: selectedTime
            )

        components.hour = selectedHour
        components.minute = selectedMinute
        components.second = 0

        if let newDate =
            calendar.date(
                from: components
            ) {

            selectedTime = newDate
        }
    }
}

// MARK: - Preview

#Preview {

    TimePickerView(
        itemName: "Evening tablet",
        selectedTime: .constant(
            Calendar.current.date(
                bySettingHour: 21,
                minute: 30,
                second: 0,
                of: Date()
            ) ?? Date()
        ),
        onClear: {},
        onDone: {}
    )
    .presentationDetents(
        [.height(490)]
    )
    .presentationDragIndicator(.hidden)
}
