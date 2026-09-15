import Foundation
import UserNotifications

// Schedules and cancels the local notification behind a TodayItem's
// "Remind me" toggle. A repeating item uses an hour/minute trigger
// with repeats: true, which iOS fires every day on its own — the app
// does not need to re-schedule it daily.
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

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: item.repeatsDaily
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
                withIdentifiers: [identifier(for: item)]
            )
    }

    private static func identifier(
        for item: TodayItem
    ) -> String {

        item.id.uuidString
    }
}

// MARK: - Foreground Presentation

private final class ReminderNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {

        completionHandler([.banner, .sound, .list])
    }
}
