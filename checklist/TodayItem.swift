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

    init(
        id: UUID = UUID(),
        text: String,
        remindAt: Date? = nil,
        checked: Bool = false,
        position: Int = 0,
        repeatsDaily: Bool = false,
        skippedDate: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.remindAt = remindAt
        self.checked = checked
        self.position = position
        self.repeatsDaily = repeatsDaily
        self.skippedDate = skippedDate
    }
}
