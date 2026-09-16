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

    init(
        id: UUID = UUID(),
        text: String,
        remindAt: Date? = nil,
        checked: Bool = false,
        position: Int = 0,
        repeatsDaily: Bool = false,
        skippedDate: Date? = nil,
        reminderEnabled: Bool = false,
        scheduledDate: Date? = nil
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
    }
}
