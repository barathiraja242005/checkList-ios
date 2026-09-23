import Foundation

// How often a task comes back.
//
// Daily is the one the app already had, and it keeps its own machinery: the
// nightly rollover regenerates it and files each day into an Occurrence. The
// longer intervals work differently — the task keeps a date, and completing
// it moves that date on to the next one due.
enum Recurrence: String, CaseIterable, Identifiable {

    case none
    case daily
    case weekly
    case biweekly
    case monthly

    var id: String { rawValue }

    var label: String {

        switch self {
        case .none: return "Never"
        case .daily: return "Every day"
        case .weekly: return "Every week"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Every month"
        }
    }

    // Shown under the row, so the choice explains itself.
    var summary: String {

        switch self {
        case .none: return "A one-off, on its own date."
        case .daily: return "Comes back every day."
        case .weekly: return "Comes back on this weekday."
        case .biweekly: return "Comes back a fortnight later."
        case .monthly: return "Comes back on this date each month."
        }
    }

    // Daily is handled by the rollover rather than by moving a date along.
    var advancesItsOwnDate: Bool {

        switch self {
        case .none, .daily: return false
        case .weekly, .biweekly, .monthly: return true
        }
    }

    private var step: (component: Calendar.Component, value: Int)? {

        switch self {
        case .none, .daily: return nil
        case .weekly: return (.weekOfYear, 1)
        case .biweekly: return (.weekOfYear, 2)
        case .monthly: return (.month, 1)
        }
    }

    // The next date this recurrence lands on after the given one.
    func nextDate(
        after date: Date
    ) -> Date? {

        guard let step
        else {
            return nil
        }

        return Calendar.current.date(
            byAdding: step.component,
            value: step.value,
            to: date
        )
    }

    // Walks forward until the date is in the future, so a task left alone for
    // a few cycles lands on its next real occurrence rather than one that has
    // already been and gone.
    func nextDate(
        onOrAfter reference: Date,
        from date: Date
    ) -> Date? {

        guard step != nil
        else {
            return nil
        }

        var candidate = date

        // Bounded so a pathological date can never spin here.
        for _ in 0..<600 {

            guard candidate < reference
            else {
                return candidate
            }

            guard let next = nextDate(after: candidate)
            else {
                return candidate
            }

            candidate = next
        }

        return candidate
    }
}

// MARK: - TodayItem

extension TodayItem {

    // `repeatsDaily` stays the source of truth for daily so the rollover and
    // everything built on it keep working untouched; the longer intervals are
    // carried alongside it.
    var recurrence: Recurrence {

        get {

            if repeatsDaily {
                return .daily
            }

            return Recurrence(rawValue: recurrenceRaw) ?? .none
        }

        set {

            repeatsDaily = newValue == .daily
            recurrenceRaw = newValue.rawValue
        }
    }

    // Moves a weekly, fortnightly or monthly task on to its next date.
    func advanceToNextOccurrence(
        now: Date = Date()
    ) {

        guard recurrence.advancesItsOwnDate
        else {
            return
        }

        let calendar = Calendar.current
        let base = scheduledDate ?? calendar.startOfDay(for: now)

        guard
            let next = recurrence.nextDate(after: base),
            let settled = recurrence.nextDate(
                onOrAfter: calendar.startOfDay(for: now),
                from: next
            )
        else {
            return
        }

        scheduledDate = calendar.startOfDay(for: settled)
        checked = false
    }
}
