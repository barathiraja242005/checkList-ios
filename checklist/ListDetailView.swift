import SwiftUI
import SwiftData

struct ListDetailView: View {

    // MARK: - List

    let list: ChecklistList

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - Items

    @Query
    private var allItems: [ChecklistListItem]

    // MARK: - Suggestions
    // TODO: Re-enable "Add from your lists" feature in the future.

    /*
    private let suggestions: [String] = [
        "Milk",
        "Eggs",
        "Avocado",
        "Olive oil",
        "Coffee",
        "Greek yogurt",
        "Bread",
        "Apples",
        "Chicken",
        "Rice"
    ]

    @State private var showingSuggestions = false
    */

    // MARK: - Add Item

    @State private var isAddingItem = false
    @State private var newItemText = ""

    // MARK: - Init

    init(list: ChecklistList) {

        self.list = list

        let listID = list.id

        _allItems = Query(
            filter: #Predicate<ChecklistListItem> {
                $0.list?.id == listID
            },
            sort: [
                SortDescriptor(\ChecklistListItem.position)
            ]
        )
    }

    // MARK: - Body

    var body: some View {

        VStack(spacing: 0) {

            header

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {

                    listHeader

                    // TODO: Re-enable "Add from your lists" feature in the future.
                    // addFromListsButton

                    itemsSection

                    addItemRow
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)

        /*
        .sheet(
            isPresented: $showingSuggestions
        ) {
            suggestionSheet
                .presentationDetents(
                    [.medium, .large]
                )
                .presentationDragIndicator(.visible)
        }
        */
    }
}

// MARK: - Header

private extension ListDetailView {

    var header: some View {

        HStack {

            Button {

                dismiss()

            } label: {

                HStack(spacing: 4) {

                    Image(
                        systemName: "chevron.left"
                    )
                    .font(
                        .system(
                            size: 14,
                            weight: .medium
                        )
                    )

                    Text("Home")
                        .font(
                            .system(size: 17)
                        )
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }
}

// MARK: - List Header

private extension ListDetailView {

    var listHeader: some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            Text(list.title)
                .font(
                    .system(
                        size: 29,
                        weight: .bold
                    )
                )
                .foregroundStyle(.primary)

            Text(list.category)
                .font(
                    .system(size: 16)
                )
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
}

/*
 // MARK: - Add From Lists
 // TODO: Re-enable this feature in the future.

private extension ListDetailView {

    var addFromListsButton: some View {

        Button {

            showingSuggestions = true

        } label: {

            HStack {

                Spacer()

                Text("Add from your lists")
                    .font(
                        .system(
                            size: 15,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.primary)

                Spacer()
            }
            .frame(height: 46)
            .background(
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
                .stroke(
                    Color(.systemGray4),
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
        .padding(.bottom, 18)
    }
}
*/

// MARK: - Items

private extension ListDetailView {

    var itemsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            ForEach(allItems) { item in

                ChecklistListItemRow(
                    item: item,
                    list: list
                )
                .frame(height: 47)

                Rectangle()
                    .fill(
                        Color(.systemGray6)
                    )
                    .frame(height: 1)
            }
        }
    }

    func moveItems(
        from source: IndexSet,
        to destination: Int
    ) {

        var reordered = allItems

        reordered.move(
            fromOffsets: source,
            toOffset: destination
        )

        for (index, item) in reordered.enumerated() {

            item.position = index
        }

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to reorder items: \(error)"
            )
        }
    }
}

// MARK: - Add Item

private extension ListDetailView {

    var addItemRow: some View {

        Group {

            if isAddingItem {

                HStack(spacing: 10) {

                    TextField(
                        "Item name",
                        text: $newItemText
                    )
                    .font(
                        .system(size: 16)
                    )

                    Button("Add") {

                        addNewItem()
                    }
                    .foregroundStyle(
                        Color(
                            red: 0.18,
                            green: 0.48,
                            blue: 0.36
                        )
                    )
                }
                .frame(minHeight: 50)

            } else {

                Button {

                    isAddingItem = true

                } label: {

                    HStack(spacing: 12) {

                        Text("+")
                            .font(
                                .system(size: 20)
                            )
                            .foregroundStyle(.secondary)

                        Text("Add item")
                            .font(
                                .system(size: 16)
                            )
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .frame(height: 50)
                }
                .buttonStyle(.plain)
            }
        }
    }

    func addNewItem() {

        let trimmed =
            newItemText
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard !trimmed.isEmpty else {
            return
        }

        let nextPosition =
            (
                allItems
                    .map { $0.position }
                    .max() ?? -1
            ) + 1

        let newItem = ChecklistListItem(
            text: trimmed,
            checked: false,
            position: nextPosition,
            list: list
        )

        modelContext.insert(newItem)

        list.updateCounts()

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to save new item: \(error)"
            )
        }

        newItemText = ""
        isAddingItem = false
    }
}

/*
 // MARK: - Suggestions Sheet
 // TODO: Re-enable this feature in the future.

private extension ListDetailView {

    var suggestionSheet: some View {

        NavigationStack {

            List {

                ForEach(
                    availableSuggestions,
                    id: \.self
                ) { suggestion in

                    Button {

                        addSuggestion(
                            suggestion
                        )

                    } label: {

                        HStack {

                            Text(suggestion)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(
                                systemName: "plus"
                            )
                            .foregroundStyle(
                                Color(
                                    red: 0.18,
                                    green: 0.48,
                                    blue: 0.36
                                )
                            )
                        }
                    }
                }
            }
            .navigationTitle(
                "Suggestions"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
        }
    }

    var availableSuggestions: [String] {

        suggestions.filter { suggestion in

            !allItems.contains {

                $0.text.caseInsensitiveCompare(
                    suggestion
                ) == .orderedSame
            }
        }
    }

    func addSuggestion(
        _ suggestion: String
    ) {

        let nextPosition =
            (
                allItems
                    .map { $0.position }
                    .max() ?? -1
            ) + 1

        let newItem = ChecklistListItem(
            text: suggestion,
            checked: false,
            position: nextPosition,
            list: list
        )

        modelContext.insert(newItem)

        list.updateCounts()

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to save suggestion: \(error)"
            )
        }
    }
}
*/

// MARK: - Preview

#Preview {

    let list = ChecklistList(
        title: "Grocery — Trader Joe's",
        category: "Grocery"
    )

    NavigationStack {

        ListDetailView(
            list: list
        )
    }
    .modelContainer(
        for: [
            ChecklistList.self,
            ChecklistListItem.self
        ],
        inMemory: true
    )
}
