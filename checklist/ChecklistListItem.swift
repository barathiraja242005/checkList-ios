import Foundation
import SwiftData

@Model
final class ChecklistListItem {

    var id: UUID
    var text: String
    var checked: Bool
    var position: Int = 0

    var list: ChecklistList?

    init(
        id: UUID = UUID(),
        text: String,
        checked: Bool = false,
        position: Int = 0,
        list: ChecklistList? = nil
    ) {
        self.id = id
        self.text = text
        self.checked = checked
        self.position = position
        self.list = list
    }
}
