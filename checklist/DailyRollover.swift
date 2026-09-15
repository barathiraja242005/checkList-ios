import Foundation
import SwiftData

// Snapshots each "Every day" item's state into a dated Occurrence
// whenever a calendar day passes, then resets it for the fresh day.
enum DailyRollover {

    private static let lastActiveDateKey = "lastActiveDate"

    static func performIfNeeded(context: ModelContext) {

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let defaults = UserDefaults.standard

        guard
            let storedLastActiveDate =
                defaults.object(forKey: lastActiveDateKey) as? Date
        else {

            defaults.set(today, forKey: lastActiveDateKey)
            return
        }

        let lastActiveDate =
            calendar.startOfDay(for: storedLastActiveDate)

        guard lastActiveDate < today
        else {
            return
        }

        let recurringItems =
            ((try? context.fetch(FetchDescriptor<TodayItem>())) ?? [])
            .filter { $0.repeatsDaily }

        var dayToClose = lastActiveDate

        while dayToClose < today {

            closeOutDay(
                dayToClose,
                recurringItems: recurringItems,
                context: context
            )

            guard
                let nextDay = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: dayToClose
                )
            else {
                break
            }

            dayToClose = nextDay
        }

        for item in recurringItems {

            item.checked = false

            if let skippedDate = item.skippedDate,
                calendar.startOfDay(for: skippedDate) < today {

                item.skippedDate = nil
            }
        }

        do {

            try context.save()

        } catch {

            print("Failed to reset recurring items: \(error)")
        }

        defaults.set(today, forKey: lastActiveDateKey)
    }

    // MARK: - Close Out Day

    private static func closeOutDay(
        _ date: Date,
        recurringItems: [TodayItem],
        context: ModelContext
    ) {

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        let occurrenceDescriptor = FetchDescriptor<Occurrence>(
            predicate: #Predicate<Occurrence> {
                $0.periodDate == dayStart
            }
        )

        let occurrence: Occurrence

        if let existing =
            try? context.fetch(occurrenceDescriptor).first {

            occurrence = existing

        } else {

            occurrence = Occurrence(periodDate: dayStart)
            context.insert(occurrence)
        }

        for item in recurringItems {

            if let skippedDate = item.skippedDate,
                calendar.isDate(skippedDate, inSameDayAs: dayStart) {

                continue
            }

            let alreadyExists = occurrence.items.contains {
                $0.sourceItemID == item.id
            }

            if alreadyExists {
                continue
            }

            let nextPosition =
                (
                    occurrence.items
                        .map { $0.position }
                        .max() ?? -1
                ) + 1

            let occurrenceItem = OccurrenceItem(
                sourceItemID: item.id,
                text: item.text,
                remindAt: item.remindAt,
                position: nextPosition,
                checked: item.checked,
                checkedAt: item.checked ? dayStart : nil,
                occurrence: occurrence
            )

            occurrence.items.append(occurrenceItem)
        }
    }
}
