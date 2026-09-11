import Foundation
import SwiftData

@Model
final class ChecklistListItem {

    var id: UUID
    var text: String
    var checked: Bool

    var list: ChecklistList?

    init(
        id: UUID = UUID(),
        text: String,
        checked: Bool = false,
        list: ChecklistList? = nil
    ) {
        self.id = id
        self.text = text
        self.checked = checked
        self.list = list
    }
}
