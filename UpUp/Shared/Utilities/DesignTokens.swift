import SwiftUI

/// Design tokens for consistent UI styling across the app
enum DesignTokens {

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 6
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
        static let xxLarge: CGFloat = 24
        static let xxxLarge: CGFloat = 32
    }

    // MARK: - Padding
    enum Padding {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 10
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
    }

    // MARK: - Font Sizes
    enum FontSize {
        static let caption2: CGFloat = 11
        static let caption: CGFloat = 12
        static let subheadline: CGFloat = 15
        static let body: CGFloat = 17
        static let headline: CGFloat = 17
        static let title3: CGFloat = 20
        static let title2: CGFloat = 22
        static let title: CGFloat = 28
        static let largeTitle: CGFloat = 34
    }

    // MARK: - Shadow
    enum Shadow {
        static let light = ShadowStyle(
            color: Color.black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )

        static let medium = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )

        static let heavy = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 12,
            x: 0,
            y: 6
        )
    }

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Colors
    enum Colors {
        // Feature colors
        static let primary = Color.blue
        static let secondary = Color.secondary
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red

        // Background colors
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
        static let secondaryGroupedBackground = Color(.secondarySystemGroupedBackground)

        // Theme colors by feature
        static let homeAccent = Color.orange
        static let logbookAccent = Color.green
        static let insightsAccent = Color.blue
    }

    // MARK: - Animation
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeOut(duration: 0.6)
    }
}

// MARK: - View Extensions for Design Tokens

extension View {
    /// Apply standard card styling
    func cardStyle(cornerRadius: CGFloat = DesignTokens.CornerRadius.medium) -> some View {
        self
            .background(DesignTokens.Colors.background)
            .cornerRadius(cornerRadius)
            .shadow(
                color: DesignTokens.Shadow.light.color,
                radius: DesignTokens.Shadow.light.radius,
                x: DesignTokens.Shadow.light.x,
                y: DesignTokens.Shadow.light.y
            )
    }

    /// Apply standard section background
    func sectionBackground(cornerRadius: CGFloat = DesignTokens.CornerRadius.medium) -> some View {
        self
            .padding()
            .background(DesignTokens.Colors.background)
            .cornerRadius(cornerRadius)
            .shadow(
                color: DesignTokens.Shadow.light.color,
                radius: DesignTokens.Shadow.light.radius,
                x: DesignTokens.Shadow.light.x,
                y: DesignTokens.Shadow.light.y
            )
    }
}
