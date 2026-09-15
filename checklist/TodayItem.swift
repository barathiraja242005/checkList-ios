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

    init(
        id: UUID = UUID(),
        text: String,
        remindAt: Date? = nil,
        checked: Bool = false,
        position: Int = 0,
        repeatsDaily: Bool = false,
        skippedDate: Date? = nil,
        reminderEnabled: Bool = false
    ) {
        self.id = id
        self.text = text
        self.remindAt = remindAt
        self.checked = checked
        self.position = position
        self.repeatsDaily = repeatsDaily
        self.skippedDate = skippedDate
        self.reminderEnabled = reminderEnabled
    }
}
