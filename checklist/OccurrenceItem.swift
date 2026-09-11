import Foundation
import SwiftData

@Model
final class OccurrenceItem {

    var id: UUID
    var sourceItemID: UUID?
    var text: String
    var remindAt: Date?
    var position: Int
    var checked: Bool
    var checkedAt: Date?
    var occurrence: Occurrence?

    init(
        id: UUID = UUID(),
        sourceItemID: UUID? = nil,
        text: String,
        remindAt: Date? = nil,
        position: Int = 0,
        checked: Bool = false,
        checkedAt: Date? = nil,
        occurrence: Occurrence? = nil
    ) {
        self.id = id
        self.sourceItemID = sourceItemID
        self.text = text
        self.remindAt = remindAt
        self.position = position
        self.checked = checked
        self.checkedAt = checkedAt
        self.occurrence = occurrence
    }
}
