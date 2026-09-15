import Foundation
import SwiftData

@Model
final class ChecklistListItem {

    var id: UUID
    var text: String
    var checked: Bool
    var position: Int = 0

    // MARK: - Scheduling

    var scheduledDate: Date?
    var hasScheduledTime: Bool
    var reminderEnabled: Bool

    // MARK: - Relationship

    var list: ChecklistList?

    init(
        id: UUID = UUID(),
        text: String,
        checked: Bool = false,
        position: Int = 0,
        scheduledDate: Date? = nil,
        hasScheduledTime: Bool = false,
        reminderEnabled: Bool = false,
        list: ChecklistList? = nil
    ) {
        self.id = id
        self.text = text
        self.checked = checked
        self.position = position
        self.scheduledDate = scheduledDate
        self.hasScheduledTime = hasScheduledTime
        self.reminderEnabled = reminderEnabled
        self.list = list
    }
}
