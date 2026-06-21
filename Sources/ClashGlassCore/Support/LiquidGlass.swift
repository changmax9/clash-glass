import SwiftUI

enum GlassCardMotion {
    static func scale(isHovering: Bool, reduceMotion: Bool) -> Double {
        guard !reduceMotion else {
            return 1
        }
        return isHovering ? 1.004 : 1
    }

    static func verticalOffset(isHovering: Bool, reduceMotion: Bool) -> Double {
        guard !reduceMotion else {
            return 0
        }
        return isHovering ? -1 : 0
    }

    static func shadowOpacity(isHovering: Bool, reduceMotion: Bool) -> Double {
        guard isHovering else {
            return 0
        }
        return reduceMotion ? 0.08 : 0.12
    }
}

enum GlassCardVisualMetrics {
    static let usesStableGlassMaterial = true
    static let clipsContentToRoundedShape = true
    static let shadowRadius: CGFloat = 12
    static let shadowVerticalOffset: CGFloat = 4
    static let overflowAllowance = shadowRadius + abs(shadowVerticalOffset)
    static let minimumPageInset = overflowAllowance + 12
}

struct GlassPalette {
    let colorScheme: ColorScheme

    var background: Color {
        colorScheme == .dark ? Color(red: 0.08, green: 0.07, blue: 0.07) : Color(red: 1.00, green: 0.97, blue: 0.97)
    }

    var cardFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.035) : Color.white.opacity(0.24)
    }

    var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)
    }

    var primaryText: Color {
        colorScheme == .dark ? Color(red: 0.94, green: 0.88, blue: 0.90) : Color(red: 0.12, green: 0.10, blue: 0.11)
    }

    var secondaryText: Color {
        colorScheme == .dark ? Color(red: 0.78, green: 0.70, blue: 0.73) : Color(red: 0.31, green: 0.27, blue: 0.28)
    }

    var tertiaryText: Color {
        colorScheme == .dark ? Color(red: 0.62, green: 0.56, blue: 0.58) : Color(red: 0.50, green: 0.45, blue: 0.46)
    }

    var rose: Color {
        colorScheme == .dark ? Color(red: 0.95, green: 0.82, blue: 0.85) : Color(red: 0.86, green: 0.74, blue: 0.77)
    }

    var brown: Color {
        colorScheme == .dark ? Color(red: 0.26, green: 0.18, blue: 0.20) : Color(red: 0.44, green: 0.35, blue: 0.37)
    }

    var railSelection: Color {
        colorScheme == .dark ? Color.white.opacity(0.18) : Color(red: 0.96, green: 0.88, blue: 0.90)
    }

    var selectionTrack: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : rose.opacity(0.10)
    }

    var selectionFill: Color {
        colorScheme == .dark ? rose.opacity(0.28) : railSelection.opacity(0.90)
    }

    var selectionHover: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : rose.opacity(0.14)
    }

    var selectionStroke: Color {
        colorScheme == .dark ? rose.opacity(0.32) : rose.opacity(0.36)
    }

    var green: Color {
        Color(red: 0.39, green: 0.91, blue: 0.65)
    }

    var shadow: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.18)
    }
}

struct LiquidGlassSurface<Content: View>: View {
    let radius: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: Content

    init(radius: CGFloat = 22, padding: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        Group {
            if #available(macOS 26.0, *) {
                content
                    .padding(padding)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: radius))
            } else {
                content
                    .padding(padding)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(.white.opacity(0.32), lineWidth: 0.8)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false
    let radius: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: Content

    init(radius: CGFloat = 26, padding: CGFloat = 28, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let palette = GlassPalette(colorScheme: colorScheme)
        Group {
            if #available(macOS 26.0, *) {
                content
                    .padding(padding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        palette.cardFill,
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous)
                    )
                    .glassEffect(
                        .clear.interactive(),
                        in: .rect(cornerRadius: radius)
                    )
            } else {
                content
                    .padding(padding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        palette.cardFill,
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous)
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(
                    isHovering ? palette.selectionStroke.opacity(0.82) : palette.cardStroke,
                    lineWidth: isHovering ? 1.7 : 1.4
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .scaleEffect(GlassCardMotion.scale(isHovering: isHovering, reduceMotion: reduceMotion))
        .offset(y: GlassCardMotion.verticalOffset(isHovering: isHovering, reduceMotion: reduceMotion))
        .brightness(isHovering ? 0.018 : 0)
        .shadow(
            color: palette.shadow.opacity(
                GlassCardMotion.shadowOpacity(isHovering: isHovering, reduceMotion: reduceMotion)
            ),
            radius: GlassCardVisualMetrics.shadowRadius,
            y: GlassCardVisualMetrics.shadowVerticalOffset
        )
        .onHover { isHovering = $0 }
        .animation(.spring(response: 0.30, dampingFraction: 0.74), value: isHovering)
    }
}

struct LiquidSectionTitle: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct StatusDot: View {
    let isOn: Bool

    var body: some View {
        Circle()
            .fill(isOn ? .green : .secondary)
            .frame(width: 9, height: 9)
            .shadow(color: (isOn ? Color.green : Color.clear).opacity(0.5), radius: 6)
    }
}
