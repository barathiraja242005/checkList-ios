import Foundation
import SwiftData

@Model
final class ChecklistList {

    var id: UUID
    var title: String
    var category: String

    var checkedCount: Int
    var totalCount: Int

    @Relationship(
        deleteRule: .cascade,
        inverse: \ChecklistListItem.list
    )
    var items: [ChecklistListItem] = []

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        checkedCount: Int = 0,
        totalCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.checkedCount = checkedCount
        self.totalCount = totalCount
    }

    func updateCounts() {

        totalCount = items.count

        checkedCount = items.filter {
            $0.checked
        }.count
    }
}
