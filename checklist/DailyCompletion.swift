import Foundation
import SwiftData

// Completion rules for a task that repeats every day.
//
// `checked` still means exactly what it always did — today's instance is
// done — and the nightly rollover still resets it. `completedThrough` carries
// the days closed ahead of time, which is what lets the Tasks tab hand the
// user the next day that is genuinely open rather than a box that is already
// ticked.
enum DailyCompletion {

    static func day(
        _ date: Date
    ) -> Date {

        Calendar.current.startOfDay(for: date)
    }

    // The next day this repeat is actually due: today, unless today is
    // already closed, and then the first day past everything closed early.
    static func nextDueDate(
        for item: TodayItem,
        now: Date = Date()
    ) -> Date {

        let calendar = Calendar.current
        let today = day(now)

        var candidate =
            item.checked
            ? calendar.date(
                byAdding: .day,
                value: 1,
                to: today
            ) ?? today
            : today

        guard let through = item.completedThrough
        else {
            return candidate
        }

        let throughDay = day(through)

        if throughDay >= candidate {

            candidate =
                calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: throughDay
                ) ?? candidate
        }

        return candidate
    }

    // Days already closed that have not yet rolled into history: today's, and
    // anything closed ahead of time.
    static func completedDates(
        for item: TodayItem,
        now: Date = Date()
    ) -> [Date] {

        let calendar = Calendar.current
        let today = day(now)

        var dates: [Date] = []

        if item.checked {
            dates.append(today)
        }

        guard let through = item.completedThrough
        else {
            return dates
        }

        let throughDay = day(through)

        var cursor =
            calendar.date(
                byAdding: .day,
                value: 1,
                to: today
            ) ?? today

        while cursor <= throughDay {

            dates.append(cursor)

            guard let next = calendar.date(
                byAdding: .day,
                value: 1,
                to: cursor
            )
            else {
                break
            }

            cursor = next
        }

        return dates
    }

    // Closes the next open day. Today's still goes through `checked`, so
    // everything else in the app keeps working unchanged; a day beyond today
    // extends completedThrough instead.
    static func closeNextDay(
        for item: TodayItem,
        now: Date = Date()
    ) {

        let today = day(now)

        let due = nextDueDate(
            for: item,
            now: now
        )

        if due <= today {

            item.checked = true

        } else {

            item.completedThrough = due
        }
    }

    // "Today" / "Tomorrow" / "Yesterday", and a written date past that.
    static func dayLabel(
        for date: Date
    ) -> String {

        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        }

        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        return date.formatted(
            .dateTime
                .weekday(.abbreviated)
                .day()
                .month(.abbreviated)
        )
    }

    // Reopens a closed day. Days are only ever closed in an unbroken run, so
    // reopening one reopens everything after it too.
    static func reopen(
        _ date: Date,
        for item: TodayItem,
        now: Date = Date()
    ) {

        let calendar = Calendar.current
        let today = day(now)
        let target = day(date)

        guard target > today
        else {

            item.checked = false
            item.completedThrough = nil

            return
        }

        let previous =
            calendar.date(
                byAdding: .day,
                value: -1,
                to: target
            ) ?? today

        item.completedThrough =
            previous <= today
            ? nil
            : previous
    }
}
