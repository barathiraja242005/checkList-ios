import Foundation
import SwiftData

// Shared removal logic for a TodayItem, used by both ItemDetailView's
// remove sheet and the swipe-to-remove action on TodayItemRow.
enum TodayItemRemoval {

    static func removeJustToday(
        _ item: TodayItem,
        context: ModelContext
    ) {

        if item.repeatsDaily {

            item.skippedDate =
                Calendar.current.startOfDay(
                    for: Date()
                )

        } else if item.recurrence.advancesItsOwnDate {

            // Nothing to skip against on these — dropping this one simply
            // moves the task on to the date it is next due.
            item.advanceToNextOccurrence()

            NotificationManager.scheduleReminder(for: item)

        } else {

            NotificationManager.cancelReminder(for: item)
            context.delete(item)
        }

        save(context)
    }

    static func removeTodayAndFuture(
        _ item: TodayItem,
        occurrences: [Occurrence],
        context: ModelContext
    ) {

        removeFutureOccurrences(
            for: item,
            occurrences: occurrences,
            context: context
        )

        NotificationManager.cancelReminder(for: item)
        context.delete(item)

        save(context)
    }

    static func removeFutureOccurrences(
        for item: TodayItem,
        occurrences: [Occurrence],
        context: ModelContext
    ) {

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for occurrence in occurrences {

            let occurrenceDate =
                calendar.startOfDay(
                    for: occurrence.periodDate
                )

            guard occurrenceDate > today
            else {
                continue
            }

            let matchingItems =
                occurrence.items.filter {
                    $0.sourceItemID == item.id
                }

            for occurrenceItem in matchingItems {
                context.delete(occurrenceItem)
            }

            occurrence.items.removeAll {
                $0.sourceItemID == item.id
            }

            if occurrence.items.isEmpty {
                context.delete(occurrence)
            }
        }
    }

    private static func save(
        _ context: ModelContext
    ) {

        do {

            try context.save()

        } catch {

            print(
                "Failed to remove item: \(error)"
            )
        }
    }
}
