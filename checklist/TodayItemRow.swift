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

        rowContent
            .navigationDestination(
                isPresented: $navigateToDetail
            ) {
                ItemDetailView(
                    item: item
                )
            }

        // MARK: - Remove Sheet
        //
        // Temporarily commented out while we rebuild
        // the remove bottom sheet step by step.
        //
        // .sheet(
        //     isPresented: $showingRemoveSheet
        // ) {
        //     RemoveItemSheet(
        //         itemText: item.text,
        //         onJustToday: {
        //             TodayItemRemoval.removeJustToday(
        //                 item,
        //                 context: modelContext
        //             )
        //
        //             showingRemoveSheet = false
        //         },
        //         onTodayAndFuture: {
        //             TodayItemRemoval.removeTodayAndFuture(
        //                 item,
        //                 occurrences: occurrences,
        //                 context: modelContext
        //             )
        //
        //             showingRemoveSheet = false
        //         },
        //         onCancel: {
        //             showingRemoveSheet = false
        //         }
        //     )
        //     .presentationSizing(.fitted)
        //     .presentationDragIndicator(.visible)
        //     .presentationBackground(Color.white)
        // }
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
                    .font(
                        .system(size: 18)
                    )
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
                .font(
                    .system(size: 16)
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding(.leading, 2)
        .frame( minHeight: 58)
        
    }
}
