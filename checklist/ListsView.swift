import SwiftUI
import SwiftData

// The Lists tab. Everything here used to sit under Today on the home screen;
// it now owns a full tab, along with the routes for creating, editing and
// opening a list.
struct ListsView: View {

    // MARK: - Navigation

    @State private var navigationPath = NavigationPath()

    // MARK: - Lists

    @Query(
        sort: [
            SortDescriptor(\ChecklistList.position),
            SortDescriptor(\ChecklistList.title)
        ]
    )
    private var lists: [ChecklistList]

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - Reordering

    @State private var draggingListID: UUID?

    // How far the lifted row has moved from where it started.
    @State private var dragTranslation: CGFloat = 0

    // The slot the lifted row would drop into. Held in state rather than
    // worked out while the view renders: every row reads it, and deriving it
    // per frame had the whole list re-animating on the smallest wobble.
    @State private var dropIndex: Int?

    // Measured per row so a title that wraps to two lines still hands off at
    // the right point mid-drag. Frozen while a drag is in flight.
    @State private var rowHeights: [UUID: CGFloat] = [:]

    // MARK: - Body

    var body: some View {

        NavigationStack(
            path: $navigationPath
        ) {

            ZStack(
                alignment: .bottomTrailing
            ) {

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 0
                    ) {

                        header

                        if lists.isEmpty {

                            emptyState

                        } else {

                            listRows
                        }
                    }
                    // Without this the column is only as wide as its widest
                    // line, which with no lists is a short piece of text —
                    // the page background then shrinks to match and leaves
                    // gutters down both sides.
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.horizontal, 34)
                    .padding(.top, 28)
                    .padding(.bottom, 110)
                }
                .scrollIndicators(.hidden)
                .scrollDisabled(draggingListID != nil)

                floatingAddButton
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .pageBackground()

            // MARK: - Navigation Destinations

            .navigationDestination(
                for: AppRoute.self
            ) { route in

                switch route {

                case .newList:

                    NewListView(
                        navigationPath: $navigationPath
                    )

                case .editList(let listID):

                    if let list =
                        lists.first(
                            where: {
                                $0.id == listID
                            }
                        ) {

                        NewListView(
                            navigationPath: $navigationPath,
                            editingList: list
                        )

                    } else {

                        Text("List not found")
                    }

                case .listDetail(let listID):

                    if let list =
                        lists.first(
                            where: {
                                $0.id == listID
                            }
                        ) {

                        ListDetailView(
                            list: list
                        )

                    } else {

                        Text("List not found")
                    }
                }
            }
        }
    }
}

// MARK: - Header

private extension ListsView {

    var header: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text("Lists")
                .font(
                    .system(
                        size: 26,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    .primary
                )

            Text(
                lists.count == 1
                    ? "1 list"
                    : "\(lists.count) lists"
            )
            .font(
                .system(size: 16)
            )
            .foregroundStyle(
                .secondary
            )
        }
    }
}

// MARK: - Rows

private extension ListsView {

    var listRows: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            Spacer()
                .frame(height: 18)

            ForEach(
                Array(lists.enumerated()),
                id: \.element.id
            ) { index, list in

                HStack(spacing: 0) {

                    ChecklistListRow(
                        list: list,
                        navigationPath: $navigationPath
                    )

                    // Only worth showing once there is something to reorder.
                    if lists.count > 1 {

                        dragHandle(for: list)
                    }
                }
                .onGeometryChange(
                    for: CGFloat.self
                ) { proxy in

                    proxy.size.height

                } action: { height in

                    // Heights are read between drags only: measuring during
                    // one feeds layout changes back into the maths driving
                    // that same layout.
                    guard draggingListID == nil
                    else {
                        return
                    }

                    rowHeights[list.id] = height
                }
                // Every offset here is a plain read of state. The displaced
                // rows animate because dropIndex is changed inside a
                // withAnimation; the lifted row is not, so it tracks the
                // finger exactly.
                .offset(
                    y: offset(forRowAt: index)
                )
                .zIndex(
                    isDragging(list) ? 1 : 0
                )
            }
        }
    }

    func dragHandle(
        for list: ChecklistList
    ) -> some View {

        Image(
            systemName: "line.3.horizontal"
        )
        .font(
            .system(size: 14)
        )
        .foregroundStyle(
            isDragging(list)
                ? Color.accentGreen
                : Color.secondary
        )
        .frame(
            width: 34,
            height: 52
        )
        .contentShape(Rectangle())
        .gesture(
            reorderGesture(for: list)
        )
    }

    var emptyState: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("No lists yet")
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .secondary
                )

            Text(
                "Tap + to make your first list."
            )
            .font(
                .system(size: 15)
            )
            .foregroundStyle(
                .secondary
            )
        }
        .padding(.top, 36)
    }
}

// MARK: - Reordering

private extension ListsView {

    // A slot only changes hands once the drag clears the halfway mark of the
    // neighbouring row by this much. Without the margin a finger resting on
    // a boundary flips the order back and forth, which is the shimmer.
    var handoverMargin: CGFloat { 10 }

    func isDragging(
        _ list: ChecklistList
    ) -> Bool {

        draggingListID == list.id
    }

    func height(
        for list: ChecklistList
    ) -> CGFloat {

        rowHeights[list.id] ?? 52
    }

    var draggingIndex: Int? {

        lists.firstIndex {
            $0.id == draggingListID
        }
    }

    func offset(
        forRowAt index: Int
    ) -> CGFloat {

        guard
            let from = draggingIndex,
            let to = dropIndex
        else {
            return 0
        }

        if index == from {
            return dragTranslation
        }

        let lifted = height(for: lists[from])

        if from < to, index > from, index <= to {
            return -lifted
        }

        if to < from, index >= to, index < from {
            return lifted
        }

        return 0
    }

    // How far the lifted row has to travel to sit exactly in a given slot:
    // the gap its displaced neighbours opened up.
    func settleOffset(
        from: Int,
        to: Int
    ) -> CGFloat {

        guard to != from
        else {
            return 0
        }

        if to > from {

            return lists[(from + 1)...to]
                .reduce(0) {
                    $0 + height(for: $1)
                }
        }

        return -lists[to..<from]
            .reduce(0) {
                $0 + height(for: $1)
            }
    }

    // Walks out from the slot currently held, a neighbour at a time, so one
    // fast drag can cross several rows in a single update.
    func dropTarget(
        from: Int,
        current: Int,
        translation: CGFloat
    ) -> Int {

        var index = current

        while index < lists.count - 1 {

            let neighbour = height(for: lists[index + 1])

            let boundary =
                settleOffset(from: from, to: index + 1)
                - neighbour / 2

            guard translation > boundary + handoverMargin
            else {
                break
            }

            index += 1
        }

        while index > 0 {

            let neighbour = height(for: lists[index - 1])

            let boundary =
                settleOffset(from: from, to: index - 1)
                + neighbour / 2

            guard translation < boundary - handoverMargin
            else {
                break
            }

            index -= 1
        }

        return index
    }

    // A press-and-hold to start, so an ordinary scroll of the page is never
    // mistaken for a reorder.
    func reorderGesture(
        for list: ChecklistList
    ) -> some Gesture {

        LongPressGesture(
            minimumDuration: 0.2
        )
        .sequenced(
            before: DragGesture(
                minimumDistance: 0
            )
        )
        .onChanged { value in

            switch value {

            case .first(true):

                beginDragging(list)

            case .second(true, let drag):

                beginDragging(list)

                guard let drag
                else {
                    return
                }

                updateDragging(
                    translation: drag.translation.height
                )

            default:
                break
            }
        }
        .onEnded { _ in

            commitReorder()
        }
    }

    func beginDragging(
        _ list: ChecklistList
    ) {

        guard draggingListID != list.id
        else {
            return
        }

        draggingListID = list.id
        dragTranslation = 0

        dropIndex =
            lists.firstIndex {
                $0.id == list.id
            }
    }

    func updateDragging(
        translation: CGFloat
    ) {

        dragTranslation = translation

        guard
            let from = draggingIndex,
            let current = dropIndex
        else {
            return
        }

        let target = dropTarget(
            from: from,
            current: current,
            translation: translation
        )

        guard target != current
        else {
            return
        }

        // Only the slot change is animated, and only when it actually
        // changes — the rows sliding aside get one spring each.
        withAnimation(
            .spring(
                response: 0.3,
                dampingFraction: 0.86
            )
        ) {
            dropIndex = target
        }
    }

    func commitReorder() {

        guard
            let from = draggingIndex,
            let to = dropIndex
        else {

            clearDragging()
            return
        }

        // Ride the row into place first, then renumber. Writing the new
        // order straight away would re-sort the query under a row still
        // sitting wherever the finger left it, which is the jump.
        withAnimation(
            .spring(
                response: 0.3,
                dampingFraction: 0.86
            )
        ) {

            dragTranslation = settleOffset(
                from: from,
                to: to
            )

        } completion: {

            applyOrder(
                from: from,
                to: to
            )

            clearDragging()
        }
    }

    func clearDragging() {

        draggingListID = nil
        dragTranslation = 0
        dropIndex = nil
    }

    func applyOrder(
        from: Int,
        to: Int
    ) {

        guard to != from
        else {
            return
        }

        var reordered = lists

        let moved = reordered.remove(at: from)

        reordered.insert(moved, at: to)

        for (index, list) in reordered.enumerated() {
            list.position = index
        }

        do {

            try modelContext.save()

        } catch {

            print(
                "Failed to reorder lists: \(error)"
            )
        }
    }
}

// MARK: - Floating Add Button

private extension ListsView {

    var floatingAddButton: some View {

        Button {

            navigationPath.append(
                AppRoute.newList
            )

        } label: {

            Image(
                systemName: "plus"
            )
            .font(
                .system(
                    size: 23,
                    weight: .medium
                )
            )
            .foregroundStyle(.white)
            .frame(
                width: 64,
                height: 64
            )
            .background(
                Color.accentGreen
            )
            .clipShape(
                Circle()
            )
        }
        .buttonStyle(.plain)
        .padding(.trailing, 24)
        .padding(.bottom, 25)
    }
}

// MARK: - Preview

#Preview {

    ListsView()
        .modelContainer(
            for: [
                TodayItem.self,
                ChecklistList.self,
                ChecklistListItem.self
            ],
            inMemory: true
        )
}
