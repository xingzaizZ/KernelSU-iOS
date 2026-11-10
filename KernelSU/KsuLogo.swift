import SwiftUI

/// KernelSU 原版图标图形（严格按上游 vector pathData 复刻）。
///
/// 上游来源（tiann/KernelSU，GPL-3.0）：
///   manager/app/src/main/res/drawable/ic_launcher_foreground.xml
///     viewport 108，group scale 0.135
///       path M 259 259 H 541 V 541 H 259 Z   strokeWidth 18  → 描边方框
///       path M 257 257 H 407 V 407 H 257 Z   fill            → 方块 A（左上）
///       path M 393 393 H 543 V 543 H 393 Z   fill            → 方块 B（右下）
///   manager/app/src/main/res/values/colors.xml
///     ic_launcher_background #FFFFFFFF
///     ic_launcher_foreground #FF1E110D
///
/// 归一化（原始坐标 × 0.135 ÷ 108）：
///   frame    0.32375 … 0.67625   stroke 0.0225（居中）
///   box A    0.32125 … 0.50875
///   box B    0.49125 … 0.67875
///   含描边的视觉包围盒  0.3125 … 0.6875（宽 0.375）
struct KsuLogo: View {
    /// 图形颜色，默认取上游 ic_launcher_foreground。
    var ink: Color = Color(hex: 0x1E110D)
    /// 底板颜色；传 nil 表示透明（只画图形）。
    var paper: Color? = .white
    var cornerRadius: CGFloat = 0

    private static let minV: CGFloat = 0.3125
    private static let span: CGFloat = 0.375
    private static let frameMin: CGFloat = 0.32375
    private static let frameSize: CGFloat = 0.3525
    private static let strokeW: CGFloat = 0.0225
    private static let aMin: CGFloat = 0.32125
    private static let boxSize: CGFloat = 0.1875
    private static let bMin: CGFloat = 0.49125

    /// 归一化坐标（0–1 空间）→ 画布像素偏移。
    /// 放在静态方法里，因为 ViewBuilder 闭包内不允许声明函数。
    private static func offset(_ normalized: CGFloat, scale k: CGFloat) -> CGFloat {
        (normalized - minV) * k
    }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let k = s / Self.span
            let ox = (geo.size.width - s) / 2
            let oy = (geo.size.height - s) / 2

            ZStack(alignment: .topLeading) {
                if let paper {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(paper)
                        .frame(width: geo.size.width, height: geo.size.height)
                }

                // 描边方框（线宽居中，同 Android strokeStyle 默认）
                Rectangle()
                    .stroke(ink, lineWidth: Self.strokeW * k)
                    .frame(width: Self.frameSize * k, height: Self.frameSize * k)
                    .offset(
                        x: ox + Self.offset(Self.frameMin, scale: k),
                        y: oy + Self.offset(Self.frameMin, scale: k)
                    )

                // 方块 A（左上）
                Rectangle()
                    .fill(ink)
                    .frame(width: Self.boxSize * k, height: Self.boxSize * k)
                    .offset(
                        x: ox + Self.offset(Self.aMin, scale: k),
                        y: oy + Self.offset(Self.aMin, scale: k)
                    )

                // 方块 B（右下），叠压在上
                Rectangle()
                    .fill(ink)
                    .frame(width: Self.boxSize * k, height: Self.boxSize * k)
                    .offset(
                        x: ox + Self.offset(Self.bMin, scale: k),
                        y: oy + Self.offset(Self.bMin, scale: k)
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// 桌面图标风格：白色圆角底 + 深色图形，和 iOS 上看到的 AppIcon 一致。
struct KsuAppMark: View {
    var size: CGFloat
    var corner: CGFloat? = nil

    var body: some View {
        KsuLogo(paper: .white, cornerRadius: corner ?? size * 0.225)
            .frame(width: size, height: size)
    }
}
