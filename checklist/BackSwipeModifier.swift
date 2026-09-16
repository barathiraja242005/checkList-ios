import SwiftUI

struct BackSwipeModifier: ViewModifier {

    @Environment(\.dismiss)
    private var dismiss

    @State private var dragAmount: CGFloat = 0

    private let triggerDistance: CGFloat = 100

    func body(content: Content) -> some View {

        content
            .gesture(
                DragGesture(
                    minimumDistance: 15,
                    coordinateSpace: .local
                )
                .onChanged { value in

                    // Only respond to a left-to-right swipe.
                    guard value.translation.width > 0 else {
                        return
                    }

                    // Ignore mostly vertical gestures.
                    guard abs(value.translation.width)
                            > abs(value.translation.height)
                    else {
                        return
                    }

                    dragAmount = value.translation.width
                }
                .onEnded { value in

                    let isRightSwipe =
                        value.translation.width > 0

                    let isHorizontal =
                        abs(value.translation.width)
                        > abs(value.translation.height)

                    guard isRightSwipe && isHorizontal else {

                        cancelSwipe()

                        return
                    }

                    if value.translation.width >= triggerDistance {

                        // Reset the gesture state before navigation.
                        dragAmount = 0

                        // Allow SwiftUI's NavigationStack
                        // to perform the back transition.
                        DispatchQueue.main.async {
                            dismiss()
                        }

                    } else {

                        cancelSwipe()
                    }
                }
            )
    }

    private func cancelSwipe() {

        withAnimation(
            .interactiveSpring(
                response: 0.38,
                dampingFraction: 0.86
            )
        ) {
            dragAmount = 0
        }
    }
}

extension View {

    func backSwipe() -> some View {
        modifier(BackSwipeModifier())
    }
}
