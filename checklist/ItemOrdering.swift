import Foundation
import SwiftData

// Chronological-by-default, drag-to-override ordering for TodayItem.
enum TodayItemOrdering {

    // Slots a newly created item into the correct chronological spot
    // among the current items, then renumbers positions 0...n so the
    // ordering stays gap-free. Untimed items always sort to the end.
    static func insertChronologically(
        _ newItem: TodayItem,
        into items: [TodayItem]
    ) {

        var ordered =
            items.sorted { $0.position < $1.position }

        let insertIndex =
            ordered.firstIndex { existing in

                guard let newTime = newItem.remindAt
                else {
                    return false
                }

                guard let existingTime = existing.remindAt
                else {
                    return true
                }

                return existingTime > newTime

            } ?? ordered.count

        ordered.insert(newItem, at: insertIndex)

        for (index, item) in ordered.enumerated() {
            item.position = index
        }
    }

    // One-time fixup so existing data (created before this feature)
    // reflects a chronological default the first time the app launches
    // with this logic. Never runs again afterward, so later manual
    // drags are never overridden.
    static func applyInitialSortIfNeeded(
        context: ModelContext
    ) {

        let key = "hasAppliedInitialChronologicalSort"
        let defaults = UserDefaults.standard

        guard !defaults.bool(forKey: key)
        else {
            return
        }

        let items =
            (try? context.fetch(FetchDescriptor<TodayItem>()))
            ?? []

        let sorted = items.sorted { a, b in

            switch (a.remindAt, b.remindAt) {

            case let (at?, bt?):
                return at < bt

            case (nil, nil):
                return a.position < b.position

            case (nil, _):
                return false

            case (_, nil):
                return true
            }
        }

        for (index, item) in sorted.enumerated() {
            item.position = index
        }

        do {

            try context.save()

        } catch {

            print(
                "Failed to apply initial chronological sort: \(error)"
            )
        }

        defaults.set(true, forKey: key)
    }
}

// MARK: - Checklist List Items

// ChecklistListItem gained a `position` field alongside drag-to-reorder
// support; existing rows all default to 0, so this assigns each list's
// items sequential positions once, preserving their prior alphabetical
// order as the starting point.
enum ChecklistListItemOrdering {

    static func applyInitialPositionsIfNeeded(
        context: ModelContext
    ) {

        let key = "hasAppliedInitialListItemPositions"
        let defaults = UserDefaults.standard

        guard !defaults.bool(forKey: key)
        else {
            return
        }

        let items =
            (try? context.fetch(FetchDescriptor<ChecklistListItem>()))
            ?? []

        let groupedByList = Dictionary(
            grouping: items,
            by: { $0.list?.id }
        )

        for (_, listItems) in groupedByList {

            let sorted =
                listItems.sorted {
                    $0.text.localizedCompare($1.text)
                        == .orderedAscending
                }

            for (index, item) in sorted.enumerated() {
                item.position = index
            }
        }

        do {

            try context.save()

        } catch {

            print(
                "Failed to apply initial list item positions: \(error)"
            )
        }

        defaults.set(true, forKey: key)
    }
}

// MARK: - Checklist Lists

// ChecklistList gained a `position` field alongside drag-to-reorder on the
// Lists tab. Existing lists all default to 0, so this hands them sequential
// positions once, keeping the alphabetical order they were shown in until
// the first drag.
enum ChecklistListOrdering {

    static func applyInitialPositionsIfNeeded(
        context: ModelContext
    ) {

        let key = "hasAppliedInitialListPositions"
        let defaults = UserDefaults.standard

        guard !defaults.bool(forKey: key)
        else {
            return
        }

        let lists =
            (try? context.fetch(FetchDescriptor<ChecklistList>()))
            ?? []

        let sorted =
            lists.sorted {
                $0.title.localizedCompare($1.title)
                    == .orderedAscending
            }

        for (index, list) in sorted.enumerated() {
            list.position = index
        }

        do {

            try context.save()

        } catch {

            print(
                "Failed to apply initial list positions: \(error)"
            )
        }

        defaults.set(true, forKey: key)
    }

    // A freshly made list goes to the bottom rather than landing in the
    // middle of an order the user arranged by hand.
    static func nextPosition(
        after lists: [ChecklistList]
    ) -> Int {

        (lists.map { $0.position }.max() ?? -1) + 1
    }
}
