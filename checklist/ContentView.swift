import SwiftUI
import SwiftData

struct ContentView: View {

    @Query(
        sort: [
            SortDescriptor(\TodayItem.position)
        ]
    )
    private var todayItems: [TodayItem]

    @Query(
        sort: [
            SortDescriptor(\ChecklistList.title)
        ]
    )
    private var lists: [ChecklistList]

    var body: some View {

        NavigationStack {

            ZStack(alignment: .bottomTrailing) {

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 0
                    ) {

                        header

                        todayItemsSection

                        listsSection
                    }
                    .padding(.horizontal, 34)
                    .padding(.top, 28)
                    .padding(.bottom, 110)
                }
                .scrollIndicators(.hidden)

                floatingAddButton
            }
            .background(Color.white)
        }
    }

    // MARK: - Visible Today Items

    private var visibleTodayItems: [TodayItem] {

        let today =
            Calendar.current.startOfDay(
                for: Date()
            )

        return todayItems.filter { item in

            guard let skippedDate = item.skippedDate
            else {
                return true
            }

            return !Calendar.current.isDate(
                skippedDate,
                inSameDayAs: today
            )
        }
    }

    // MARK: - Header

    private var header: some View {

        NavigationLink {

            TodayDatedView()

        } label: {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Today")
                    .font(
                        .system(
                            size: 29,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {

                    Text(
                        Date(),
                        format: .dateTime
                            .weekday(.wide)
                            .day()
                            .month(.wide)
                    )

                    Text("·")

                    Text(
                        "\(completedCount) of \(visibleTodayItems.count) done"
                    )

                    Image(
                        systemName: "chevron.right"
                    )
                    .font(
                        .system(
                            size: 11,
                            weight: .semibold
                        )
                    )
                }
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var completedCount: Int {

        visibleTodayItems.filter {
            $0.checked
        }.count
    }

    // MARK: - Today Items

    private var todayItemsSection: some View {

        VStack(spacing: 0) {

            Spacer()
                .frame(height: 38)

            ForEach(visibleTodayItems) { item in

                TodayItemRow(
                    item: item
                )
            }

            addItemRow
        }
    }

    private var addItemRow: some View {

        Button {

            // Add item functionality will be built later.

        } label: {

            HStack(spacing: 18) {

                Text("+")
                    .font(.system(size: 21))
                    .foregroundStyle(.secondary)

                Text("Add item")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .frame(height: 58)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lists

    private var listsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            Text("Lists")
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.secondary)
                .padding(.top, 25)
                .padding(.bottom, 18)

            ForEach(lists) { list in

                ChecklistListRow(
                    list: list
                )
            }
        }
    }

    // MARK: - Floating Add Button

    private var floatingAddButton: some View {

        NavigationLink {

            NewListView()

        } label: {

            Image(systemName: "plus")
                .font(
                    .system(
                        size: 25,
                        weight: .medium
                    )
                )
                .foregroundStyle(.white)
                .frame(
                    width: 64,
                    height: 64
                )
                .background(
                    Color(
                        red: 0.12,
                        green: 0.42,
                        blue: 0.31
                    )
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 24)
        .padding(.bottom, 25)
    }
}

#Preview {

    ContentView()
        .modelContainer(
            for: [
                TodayItem.self,
                ChecklistList.self
            ],
            inMemory: true
        )
}
