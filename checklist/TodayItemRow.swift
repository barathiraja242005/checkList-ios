import SwiftUI
import SwiftData

struct TodayItemRow: View {

    @Bindable var item: TodayItem

    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var occurrences: [Occurrence]

    @State private var navigateToDetail = false
    @State private var showingRemoveSheet = false

    var body: some View {

        SwipeActionRow(
            content: {
                rowContent
            },
            onEdit: {
                navigateToDetail = true
            },
            onDelete: {

                // The sheet only offers a meaningful choice for repeating
                // items; a one-off item has no future days to keep.
                guard item.repeatsDaily
                else {

                    TodayItemRemoval.removeTodayAndFuture(
                        item,
                        occurrences: occurrences,
                        context: modelContext
                    )

                    return
                }

                showingRemoveSheet = true
            }
        )
        .navigationDestination(
            isPresented: $navigateToDetail
        ) {
            ItemDetailView(
                item: item
            )
        }

        // MARK: - Remove Sheet
        .sheet(
            isPresented: $showingRemoveSheet
        ) {
            RemoveItemSheet(
                itemText: item.text,
                onJustToday: {
                    TodayItemRemoval.removeJustToday(
                        item,
                        context: modelContext
                    )

                    showingRemoveSheet = false
                },
                onTodayAndFuture: {
                    TodayItemRemoval.removeTodayAndFuture(
                        item,
                        occurrences: occurrences,
                        context: modelContext
                    )

                    showingRemoveSheet = false
                },
                onCancel: {
                    showingRemoveSheet = false
                }
            )
            .presentationDetents([.height(290)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.white)
        }
    }

    // MARK: - Row Content

    private var rowContent: some View {

        HStack(spacing: 16) {

            // MARK: - Checkbox

            Button {
                item.checked.toggle()
            } label: {
                CheckmarkBox(
                    isChecked: item.checked
                )
            }
            .buttonStyle(.plain)

            // MARK: - Item Name

            Button {
                navigateToDetail = true
            } label: {
                Text(item.text)
                    .font(.system(size: 18))
                    .foregroundStyle(
                        item.checked
                            ? Color.secondary
                            : Color.primary
                    )
                    .strikethrough(
                        item.checked,
                        color: .secondary
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
            .buttonStyle(.plain)

            // MARK: - Time

            if let remindAt = item.remindAt {

                Text(
                    remindAt,
                    format: .dateTime
                        .hour()
                        .minute()
                )
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 2)
        .frame(minHeight: 58)
    }
}
