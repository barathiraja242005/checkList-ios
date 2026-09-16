import SwiftUI

struct CheckmarkBox: View {
    
    let isChecked: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                isChecked
                ? Color.accentGreen
                // Clear rather than white, so the page tint shows through and
                // the box matches the checkboxes used in the lists.
                : Color.clear
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
                                size: 12,
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
