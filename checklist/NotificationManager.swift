import Foundation
import UserNotifications

// Schedules and cancels local notifications for TodayItem
// and ChecklistListItem reminders.

enum NotificationManager {

    private static let delegate = ReminderNotificationDelegate()

    static func configure() {
        UNUserNotificationCenter.current().delegate = delegate
    }

    static func requestAuthorization(
        completion: @escaping (Bool) -> Void
    ) {
        UNUserNotificationCenter.current()
            .requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
    }

    // MARK: - TodayItem

    static func scheduleReminder(
        for item: TodayItem
    ) {
        cancelReminder(for: item)

        guard
            item.reminderEnabled,
            let remindAt = item.remindAt
        else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = item.text
        content.body = "It's time for \(item.text)."
        content.sound = .default

        let calendar = Calendar.current

        var components = DateComponents()

        components.hour =
            calendar.component(.hour, from: remindAt)

        components.minute =
            calendar.component(.minute, from: remindAt)

        // Daily, weekly and monthly are shapes a calendar trigger can repeat
        // on its own. A fortnight is not, so that one is booked as a single
        // notification for its next date and rebooked when the task moves on.
        var repeats = false

        switch item.recurrence {

        case .daily:

            repeats = true

        case .weekly:

            if let scheduledDate = item.scheduledDate {

                components.weekday =
                    calendar.component(.weekday, from: scheduledDate)

                repeats = true
            }

        case .monthly:

            if let scheduledDate = item.scheduledDate {

                components.day =
                    calendar.component(.day, from: scheduledDate)

                repeats = true
            }

        case .biweekly, .none:

            // A dated task fires on its date rather than at the next time of
            // day those hands come round.
            if let scheduledDate = item.scheduledDate {

                let day = calendar.dateComponents(
                    [.year, .month, .day],
                    from: scheduledDate
                )

                components.year = day.year
                components.month = day.month
                components.day = day.day
            }
        }

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: repeats
        )

        let request = UNNotificationRequest(
            identifier: identifier(for: item),
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminder(
        for item: TodayItem
    ) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    identifier(for: item)
                ]
            )
    }

    private static func identifier(
        for item: TodayItem
    ) -> String {
        item.id.uuidString
    }

    // MARK: - ChecklistListItem

    static func scheduleReminder(
        for item: ChecklistListItem
    ) {
        cancelReminder(for: item)

        guard
            item.reminderEnabled,
            let scheduledDate = item.scheduledDate
        else {
            return
        }

        let calendar = Calendar.current

        let hasTime =
            calendar.component(.hour, from: scheduledDate) != 0 ||
            calendar.component(.minute, from: scheduledDate) != 0

        guard hasTime else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = item.text
        content.body = "It's time for \(item.text)."
        content.sound = .default

        var components = DateComponents()

        components.year =
            calendar.component(.year, from: scheduledDate)

        components.month =
            calendar.component(.month, from: scheduledDate)

        components.day =
            calendar.component(.day, from: scheduledDate)

        components.hour =
            calendar.component(.hour, from: scheduledDate)

        components.minute =
            calendar.component(.minute, from: scheduledDate)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier(for: item),
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminder(
        for item: ChecklistListItem
    ) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    identifier(for: item)
                ]
            )
    }

    private static func identifier(
        for item: ChecklistListItem
    ) -> String {
        item.id.uuidString
    }
}

// MARK: - Foreground Presentation

private final class ReminderNotificationDelegate:
    NSObject,
    UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([
            .banner,
            .sound,
            .list
        ])
    }
}
