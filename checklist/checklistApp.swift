import SwiftUI
import SwiftData

@main
struct checklistApp: App {

    let container: ModelContainer

    init() {

        do {

            container = try ModelContainer(
                for:
                    TodayItem.self,
                    ChecklistList.self,
                    ChecklistListItem.self,
                    Occurrence.self,
                    OccurrenceItem.self
            )

            let context = container.mainContext

            let existingItems = try context.fetch(
                FetchDescriptor<TodayItem>()
            )

            if existingItems.isEmpty {

                addSampleData(
                    to: context
                )
            }

        } catch {

            fatalError(
                "Failed to create ModelContainer: \(error)"
            )
        }
    }

    var body: some Scene {

        WindowGroup {

            ContentView()
        }
        .modelContainer(container)
    }

    private func addSampleData(
        to context: ModelContext
    ) {

        let calendar = Calendar.current

        func time(
            hour: Int,
            minute: Int
        ) -> Date {

            calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: Date()
            ) ?? Date()
        }

        // MARK: Today

        context.insert(
            TodayItem(
                text: "Run",
                remindAt: time(
                    hour: 6,
                    minute: 30
                ),
                checked: true,
                position: 0
            )
        )

        context.insert(
            TodayItem(
                text: "Morning tablet",
                remindAt: time(
                    hour: 8,
                    minute: 0
                ),
                checked: true,
                position: 1
            )
        )

        context.insert(
            TodayItem(
                text: "Vitamin D",
                remindAt: time(
                    hour: 8,
                    minute: 0
                ),
                checked: true,
                position: 2
            )
        )

        context.insert(
            TodayItem(
                text: "Evening tablet",
                remindAt: time(
                    hour: 21,
                    minute: 30
                ),
                position: 3
            )
        )

        context.insert(
            TodayItem(
                text: "Ten minutes of reading",
                remindAt: time(
                    hour: 21,
                    minute: 30
                ),
                position: 4
            )
        )

        context.insert(
            TodayItem(
                text: "Make the bed",
                position: 5
            )
        )
    }
}
