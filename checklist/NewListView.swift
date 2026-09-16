import SwiftUI
import SwiftData

struct NewListView: View {

    @Binding var navigationPath: NavigationPath

    // Passing a list turns this screen into an editor for it; nil creates one.
    var editingList: ChecklistList? = nil

    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var existingLists: [ChecklistList]

    @State private var listName = ""
    @State private var selectedCategory = "Grocery"

    private var isEditing: Bool {
        editingList != nil
    }

    private let categories = [
        "Grocery",
        "Packing",
        "Moving",
        "Wedding",
        "Home",
        "Work",
        "Errands",
        "Health",
        "Other"
    ]

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - Top Bar

            HStack {

                Button {

                    navigationPath.removeLast()

                } label: {

                    HStack(spacing: 4) {

                        Image(
                            systemName: "chevron.left"
                        )
                        .font(
                            .system(
                                size: 12,
                                weight: .medium
                            )
                        )

                        Text("Cancel")
                            .font(
                                .system(size: 16)
                            )
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 26)
            .padding(.top, 12)
            .padding(.bottom, 10)

            // MARK: - Content

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {

                    Text(
                        isEditing
                        ? "Edit list"
                        : "New list"
                    )
                        .font(
                            .system(
                                size: 26,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.primary)
                        .padding(.bottom, 25)

                    // MARK: - List Name

                    TextField(
                        "Grocery — Trader Joe's",
                        text: $listName
                    )
                    .font(
                        .system(size: 22)
                    )
                    .textFieldStyle(.plain)
                    .padding(.bottom, 9)
                    .overlay(
                        Rectangle()
                            .fill(Color.primary)
                            .frame(height: 1),
                        alignment: .bottom
                    )

                    // MARK: - Explanation

                    Text(
                        "Pick a category so the app can suggest items\n" +
                        "you've used before."
                    )
                    .font(
                        .system(size: 15)
                    )
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
                    .padding(.bottom, 14)

                    categoryChips
                }
                .padding(.horizontal, 26)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }

            // MARK: - Create Button

            Button {

                createList()

            } label: {

                Text(
                    isEditing
                    ? "Save changes"
                    : "Create list"
                )
                    .font(
                        .system(
                            size: 17,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 58)
                    .background(
                        Color.accentGreen
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 15,
                            style: .continuous
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(
                listName
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
            )
            .opacity(
                listName
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
                ? 0.5
                : 1
            )
            .padding(.horizontal, 26)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .pageBackground()
        .onAppear {

            guard let editingList
            else {
                return
            }

            listName = editingList.title
            selectedCategory = editingList.category
        }
        .navigationBarBackButtonHidden(true)
        .backSwipe()
    }
}

// MARK: - Category Chips

private extension NewListView {

    var categoryChips: some View {

        LazyVGrid(
            columns: [

                GridItem(
                    .flexible(),
                    spacing: 9
                ),

                GridItem(
                    .flexible(),
                    spacing: 9
                ),

                GridItem(
                    .flexible(),
                    spacing: 9
                )
            ],
            alignment: .leading,
            spacing: 9
        ) {

            ForEach(
                categories,
                id: \.self
            ) { category in

                Button {

                    selectedCategory = category

                } label: {

                    Text(category)
                        .font(
                            .system(
                                size: 15
                            )
                        )
                        .foregroundStyle(
                            selectedCategory == category
                            ? Color.appBackground
                            : Color.primary
                        )
                        .frame(
                            maxWidth: .infinity
                        )
                        .frame(height: 40)
                        .background(
                            selectedCategory == category
                            ? Color.primary
                            : Color.clear
                        )
                        .clipShape(
                            Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    Color(
                                        .systemGray4
                                    ),
                                    lineWidth:
                                        selectedCategory == category
                                        ? 0
                                        : 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Create List

private extension NewListView {

    func createList() {

        let trimmedName =
            listName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedName.isEmpty else {
            return
        }

        if let editingList {

            editingList.title = trimmedName
            editingList.category = selectedCategory

            do {

                try modelContext.save()

                // Editing was pushed from the list, so just go back to it.
                navigationPath.removeLast()

            } catch {

                print(
                    "Failed to save list: \(error)"
                )
            }

            return
        }

        let newList = ChecklistList(
            title: trimmedName,
            category: selectedCategory,
            position:
                ChecklistListOrdering.nextPosition(
                    after: existingLists
                )
        )

        modelContext.insert(newList)

        do {

            try modelContext.save()

            // Replace New List with List Detail.
            navigationPath.removeLast()

            navigationPath.append(
                AppRoute.listDetail(
                    newList.id
                )
            )

        } catch {

            print(
                "Failed to save list: \(error)"
            )
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        NewListView(
            navigationPath:
                .constant(
                    NavigationPath()
                )
        )
    }
    .modelContainer(
        for: [
            ChecklistList.self
        ],
        inMemory: true
    )
}
