import SwiftUI

struct ChecklistListRow: View {

    let list: ChecklistList

    var body: some View {

        NavigationLink {

            ListDetailView(
                list: list
            )

        } label: {

            HStack {

                Text(list.title)
                    .font(.system(size: 18))
                    .foregroundStyle(.primary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                Text(
                    "\(list.checkedCount)/\(list.totalCount)"
                )
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            }
            .frame(minHeight: 59)
            .overlay(
                alignment: .bottom
            ) {

                Rectangle()
                    .fill(
                        Color(.systemGray5)
                    )
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
