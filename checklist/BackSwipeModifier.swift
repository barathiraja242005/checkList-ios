import SwiftUI
import UIKit

// Hiding the navigation bar's back button also disables UIKit's interactive
// pop gesture, which is why this app previously hand-rolled a swipe that
// offset the page over a blank background. That could never match the system
// transition, which slides the current screen off while revealing the one
// underneath, tracking the finger in real time.
//
// Re-enabling the real recogniser gives that transition back, with the
// custom back buttons left as they are.
private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(
        context: Context
    ) -> UIViewController {

        Enabler(coordinator: context.coordinator)
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {}

    // The recogniser needs a delegate once its default one is bypassed, or
    // it refuses to begin. Popping is allowed whenever something is stacked
    // above the root.
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        weak var navigationController: UINavigationController?

        func gestureRecognizerShouldBegin(
            _ gestureRecognizer: UIGestureRecognizer
        ) -> Bool {

            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }

    final class Enabler: UIViewController {

        private let coordinator: Coordinator

        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not used")
        }

        override func didMove(
            toParent parent: UIViewController?
        ) {
            super.didMove(toParent: parent)
            enableInteractivePop()
        }

        override func viewDidAppear(
            _ animated: Bool
        ) {
            super.viewDidAppear(animated)
            enableInteractivePop()
        }

        private func enableInteractivePop() {

            guard let navigationController =
                    enclosingNavigationController()
            else {
                return
            }

            coordinator.navigationController =
                navigationController

            navigationController
                .interactivePopGestureRecognizer?
                .isEnabled = true

            navigationController
                .interactivePopGestureRecognizer?
                .delegate = coordinator
        }

        private func enclosingNavigationController()
            -> UINavigationController? {

            var candidate: UIViewController? = parent

            while let current = candidate {

                if let navigationController =
                    current as? UINavigationController {

                    return navigationController
                }

                candidate = current.parent
            }

            return navigationController
        }
    }
}

extension View {

    func backSwipe() -> some View {

        background(
            InteractivePopGestureEnabler()
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        )
    }
}
