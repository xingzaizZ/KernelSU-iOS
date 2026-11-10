import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

enum Theme {
    static let bg         = Color(hex: 0x0A0E12)
    static let bgElevated = Color(hex: 0x10161D)
    static let card       = Color(hex: 0x151C24)
    static let stroke     = Color(hex: 0x24303C)
    static let strokeSoft = Color(hex: 0x1B232C)

    static let accent     = Color(hex: 0x4ADE80)
    static let accentDeep = Color(hex: 0x16A34A)
    static let warn       = Color(hex: 0xFBBF24)
    static let danger     = Color(hex: 0xF87171)
    static let info       = Color(hex: 0x60A5FA)

    static let text       = Color(hex: 0xE8EEF4)
    static let subtext    = Color(hex: 0x8C9AAB)
    static let faint      = Color(hex: 0x5B6673)

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

struct KsCard<Content: View>: View {
    var padding: CGFloat = 16
    let content: () -> Content

    init(padding: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.strokeSoft, lineWidth: 1)
            )
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1.4)
                .foregroundColor(Theme.faint)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(Theme.mono(11))
                    .foregroundColor(Theme.faint)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct KVRow: View {
    let key: String
    let value: String
    var valueColor: Color = Theme.text

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(key)
                .font(Theme.mono(12))
                .foregroundColor(Theme.subtext)
                .frame(width: 108, alignment: .leading)
            Text(value)
                .font(Theme.mono(12))
                .foregroundColor(valueColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}

struct PulseDot: View {
    var color: Color = Theme.accent
    @State private var on = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: 20, height: 20)
                .scaleEffect(on ? 1.5 : 0.8)
                .opacity(on ? 0 : 0.9)
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                on = true
            }
        }
    }
}
