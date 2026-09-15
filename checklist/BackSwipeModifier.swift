import SwiftUI

struct BackSwipeModifier: ViewModifier {

    @Environment(\.dismiss)
    private var dismiss

    @State private var dragOffset: CGFloat = 0

    private let triggerDistance: CGFloat = 100

    func body(content: Content) -> some View {
        content
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 20)
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

                        dragOffset = value.translation.width
                    }
                    .onEnded { value in

                        guard value.translation.width > 0 else {
                            withAnimation(.easeOut(duration: 0.2)) {
                                dragOffset = 0
                            }
                            return
                        }

                        guard abs(value.translation.width)
                                > abs(value.translation.height)
                        else {
                            withAnimation(.easeOut(duration: 0.2)) {
                                dragOffset = 0
                            }
                            return
                        }

                        if value.translation.width >= triggerDistance {

                            withAnimation(.easeOut(duration: 0.15)) {
                                dragOffset = 80
                            }

                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.1
                            ) {
                                dismiss()
                            }

                        } else {

                            withAnimation(.easeOut(duration: 0.2)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
    }
}

extension View {

    func backSwipe() -> some View {
        modifier(BackSwipeModifier())
    }
}
