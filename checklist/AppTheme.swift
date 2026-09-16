import SwiftUI
import UIKit

// The palette is defined through UIColor's dynamic provider so every colour
// resolves against the current appearance. SwiftUI's own semantic colours
// (.primary, .secondary, systemGray*) already adapt; these are the ones the
// app hardcodes, which would otherwise stay fixed in dark mode.
extension Color {

    private static func adaptive(
        light: (CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat)
    ) -> Color {

        Color(
            UIColor { traits in

                let rgb =
                    traits.userInterfaceStyle == .dark
                    ? dark
                    : light

                return UIColor(
                    red: rgb.0,
                    green: rgb.1,
                    blue: rgb.2,
                    alpha: 1
                )
            }
        )
    }

    // #F2F8F5 light, #101614 dark — the dark side keeps a green cast rather
    // than going neutral black, so both appearances share a family.
    static let appBackground = adaptive(
        light: (0.949, 0.973, 0.961),
        dark: (0.063, 0.086, 0.078)
    )

    // The brand green. Lifted considerably in dark mode: the light value is
    // far too dim to read against a near-black page.
    static let accentGreen = adaptive(
        light: (0.18, 0.48, 0.36),
        dark: (0.36, 0.76, 0.56)
    )

    // Overdue amber, brightened for dark.
    static let overdueAmber = adaptive(
        light: (0.72, 0.44, 0.05),
        dark: (0.95, 0.70, 0.30)
    )

    // The swipe delete fill.
    static let deleteRed = adaptive(
        light: (0.70, 0.13, 0.13),
        dark: (0.80, 0.24, 0.22)
    )

    // A raised surface sitting on the page: the time picker's selection band
    // and similar. Light in light mode, lifted just off the background in
    // dark, so wheel text stays legible either way.
    static let appSurface = adaptive(
        light: (0.950, 0.950, 0.940),
        dark: (0.150, 0.180, 0.165)
    )

    // The tinted fill behind an active chip — the accent at low intensity.
    static let accentSoft = adaptive(
        light: (0.920, 0.960, 0.940),
        dark: (0.145, 0.235, 0.190)
    )
}

// MARK: - Page Background

// The swipe row paints an opaque fill to hide the reveal layer behind it, so
// it has to know the colour of the page it is sitting on. Carrying that in
// the environment keeps the two from drifting apart.
private struct PageBackgroundKey: EnvironmentKey {

    static let defaultValue = Color.appBackground
}

extension EnvironmentValues {

    var pageBackground: Color {
        get { self[PageBackgroundKey.self] }
        set { self[PageBackgroundKey.self] = newValue }
    }
}

extension View {

    func pageBackground(
        _ color: Color = .appBackground
    ) -> some View {

        background(color)
            .environment(\.pageBackground, color)
    }
}
