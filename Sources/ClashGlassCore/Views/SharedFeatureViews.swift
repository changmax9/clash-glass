import SwiftUI

enum PageSurfaceMetrics {
    static let horizontalInset: CGFloat = 28
    static let topInset: CGFloat = 28

    static func contentWidth(availableWidth: CGFloat) -> CGFloat {
        max(0, availableWidth - horizontalInset * 2)
    }
}

enum PageScrollSurfaceMetrics {
    static let clipsToViewport = true
}

struct FeaturePage<Content: View>: View {
    var searchText: Binding<String>? = nil
    let placeholder: String
    let actions: [FeatureAction]
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                if let searchText {
                    SearchCapsule(text: searchText, placeholder: placeholder)
                        .frame(width: 280)
                }

                Spacer(minLength: 12)

                ForEach(actions) { action in
                    LiquidIconButton(
                        title: action.title,
                        symbol: action.symbol,
                        size: 32,
                        action: action.action
                    )
                    .disabled(action.isDisabled)
                    .opacity(action.isDisabled ? 0.55 : 1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .padding(.horizontal, PageSurfaceMetrics.horizontalInset)

            ScrollView(.vertical) {
                content
                    .padding(.top, PageSurfaceMetrics.topInset)
                    .padding(.horizontal, PageSurfaceMetrics.horizontalInset)
                    .padding(.bottom, 96)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .scrollIndicators(.hidden)
        }
    }
}

struct FeatureAction: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
    var isDisabled = false
    let action: () -> Void
}

struct SearchCapsule: View {
    @Binding var text: String
    let placeholder: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = GlassPalette(colorScheme: colorScheme)
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.tertiaryText)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background {
            LiquidGlassSurface(radius: 16, padding: 0) {
                Color.clear
            }
        }
    }
}

struct PillSegment<Value: Hashable & Identifiable>: View where Value.ID == Value {
    let values: [Value]
    @Binding var selection: Value
    let title: (Value) -> String
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var selectionNamespace
    @State private var hoveredValue: Value?

    var body: some View {
        let palette = GlassPalette(colorScheme: colorScheme)
        HStack(spacing: 4) {
            ForEach(values) { value in
                Button {
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
                        selection = value
                    }
                } label: {
                    Text(title(value))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(selection == value ? palette.brown : palette.secondaryText)
                        .frame(height: 26)
                        .padding(.horizontal, 10)
                        .background {
                            if selection == value {
                                selectedSurface
                                    .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                            } else if hoveredValue == value {
                                Capsule(style: .continuous)
                                    .fill(palette.selectionHover)
                            }
                        }
                }
                .buttonStyle(.plain)
                .scaleEffect(hoveredValue == value ? 1.025 : 1)
                .onHover { hovering in
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.76)) {
                        hoveredValue = hovering ? value : nil
                    }
                }
            }
        }
        .padding(3)
        .background {
            Capsule(style: .continuous)
                .fill(palette.selectionTrack)
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(palette.selectionStroke.opacity(0.48), lineWidth: 0.8)
                }
        }
    }

    private var selectedSurface: some View {
        let palette = GlassPalette(colorScheme: colorScheme)
        return Capsule(style: .continuous)
            .fill(palette.selectionFill)
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(palette.selectionStroke, lineWidth: 0.8)
            }
    }
}

struct StatusChip: View {
    let text: String
    let symbol: String?
    var tint: Color? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .frame(height: 22)
        .foregroundStyle(tint ?? .secondary)
        .background((tint ?? Color.secondary).opacity(0.12), in: Capsule(style: .continuous))
    }
}

struct EmptyGlassState: View {
    let title: String
    let symbol: String

    var body: some View {
        GlassCard(radius: 16, padding: 26) {
            VStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
        }
    }
}
