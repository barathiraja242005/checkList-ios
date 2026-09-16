import SwiftUI

struct CheckmarkBox: View {

    let isChecked: Bool

    var body: some View {

        RoundedRectangle(cornerRadius: 6)
            .fill(
                isChecked
                ? Color(
                    red: 0.12,
                    green: 0.42,
                    blue: 0.31
                )
                : Color(.systemBackground)
            )
            .overlay {

                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isChecked
                        ? Color.clear
                        : Color(.systemGray3),
                        lineWidth: 1.5
                    )
            }
            .overlay {

                if isChecked {

                    Image(systemName: "checkmark")
                        .font(
                            .system(
                                size: 13,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                }
            }
            .frame(
                width: 24,
                height: 24
            )
    }
}
