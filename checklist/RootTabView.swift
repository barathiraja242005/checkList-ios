import SwiftUI
import SwiftData

// The app's base deck. Each tab owns its own NavigationStack so pushing a
// detail screen on one tab never disturbs where the others are parked.
struct RootTabView: View {

    var body: some View {

        TabView {

            Tab(
                "Today",
                systemImage: "calendar"
            ) {

                ContentView()
            }

            Tab(
                "Tasks",
                systemImage: "checkmark.circle"
            ) {

                TasksView()
            }

            Tab(
                "Lists",
                systemImage: "checklist"
            ) {

                ListsView()
            }

            Tab(
                "Reminders",
                systemImage: "bell"
            ) {

                RemindersView()
            }
        }
        .tint(Color.accentGreen)
    }
}

// MARK: - Preview

#Preview {

    RootTabView()
        .modelContainer(
            for: [
                TodayItem.self,
                ChecklistList.self,
                ChecklistListItem.self
            ],
            inMemory: true
        )
}
