import Foundation
import SwiftData

@Model
final class TodayItem {

    var id: UUID
    var text: String
    var remindAt: Date?
    var checked: Bool
    var position: Int
    var repeatsDaily: Bool
    var skippedDate: Date?
    var reminderEnabled: Bool = false

    // The day this task belongs to. A one-off task is dated when it is
    // created and falls into Overdue once that day passes; nil means the
    // task is open-ended and simply stays on Today. Repeating tasks ignore
    // this entirely, since they are regenerated each day.
    var scheduledDate: Date?

    // Parks the task in Home's Later section instead of Today: something to
    // get to eventually, with no day attached. Later tasks never carry a
    // date or a repeat, so they never roll into Overdue.
    var isLater: Bool = false

    // For a daily repeat: the last day closed ahead of time. Today's own
    // state stays in `checked`; this covers the run of days after it, so the
    // Tasks tab can show the next day that is still open.
    var completedThrough: Date?

    init(
        id: UUID = UUID(),
        text: String,
        remindAt: Date? = nil,
        checked: Bool = false,
        position: Int = 0,
        repeatsDaily: Bool = false,
        skippedDate: Date? = nil,
        reminderEnabled: Bool = false,
        scheduledDate: Date? = nil,
        isLater: Bool = false,
        completedThrough: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.remindAt = remindAt
        self.checked = checked
        self.position = position
        self.repeatsDaily = repeatsDaily
        self.skippedDate = skippedDate
        self.reminderEnabled = reminderEnabled
        self.scheduledDate = scheduledDate
        self.isLater = isLater
        self.completedThrough = completedThrough
    }
}
