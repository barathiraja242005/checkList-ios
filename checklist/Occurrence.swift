import Foundation
import SwiftData

@Model
final class Occurrence {

    var id: UUID
    var periodDate: Date
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var items: [OccurrenceItem]

    init(
        id: UUID = UUID(),
        periodDate: Date,
        createdAt: Date = Date(),
        items: [OccurrenceItem] = []
    ) {
        self.id = id
        self.periodDate = periodDate
        self.createdAt = createdAt
        self.items = items
    }
}
