import SwiftUI
import UIKit

/// 启动引导动画：逐行输出伪内核日志，结束后淡出。
/// 纯本地定时字符串，不探测任何系统状态。
struct BootOverlay: View {
    let onFinish: () -> Void

    @State private var visibleLines: [BootLine] = []
    @State private var progress: CGFloat = 0
    @State private var phase: Phase = .scanning

    enum Phase {
        case scanning
        case ready
    }

    private static let script: [BootLine] = [
        BootLine(text: "kernelsu: initializing ios backend", tint: .dim),
        BootLine(text: "kpatch: loading payload (arm64e)", tint: .normal),
        BootLine(text: "kpatch: text patch applied @ 0xfffffff0079a4c20", tint: .normal),
        BootLine(text: "kernelsu: su channel established", tint: .ok),
        BootLine(text: "selinux: set to permissive", tint: .normal),
        BootLine(text: "susfs: version 1.5.2 mounted", tint: .normal),
        BootLine(text: "manager: verifying bundle integrity", tint: .dim),
        BootLine(text: "manager: uid=0(root) gid=0(wheel)", tint: .ok),
        BootLine(text: "modules: loader disabled in this build", tint: .warn),
        BootLine(text: "kernelsu: ready", tint: .ok)
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            RadialGradient(
                colors: [Theme.accent.opacity(0.10), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                emblem
                    .padding(.bottom, 26)

                Text("KernelSU")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                    .tracking(0.5)

                Text("iOS · kernel privilege manager")
                    .font(Theme.mono(10.5))
                    .foregroundColor(Theme.faint)
                    .padding(.top, 4)

                Spacer()

                logPanel
                    .padding(.horizontal, 26)
                    .padding(.bottom, 18)

                progressBar
                    .padding(.horizontal, 26)
                    .padding(.bottom, 12)

                Text(phase == .ready ? "ACCESS GRANTED" : "INITIALIZING")
                    .font(Theme.mono(9, weight: .bold))
                    .tracking(3)
                    .foregroundColor(phase == .ready ? Theme.accent : Theme.faint)
                    .padding(.bottom, 54)
            }
        }
        .task { await play() }
    }

    private var emblem: some View {
        KsuAppMark(size: 104)
            .shadow(color: Theme.accent.opacity(0.18), radius: 26)
            .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
    }

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(visibleLines) { line in
                Text(line.text)
                    .font(Theme.mono(9.5))
                    .foregroundColor(line.tint.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 132, alignment: .bottomLeading)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.strokeSoft)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Theme.accentDeep, Theme.accent],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geo.size.width * progress))
            }
        }
        .frame(height: 3)
    }

    private func play() async {
        for line in Self.script {
            try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 90...180) * 1_000_000))
            withAnimation(.easeOut(duration: 0.12)) {
                visibleLines.append(line)
                if visibleLines.count > 8 {
                    visibleLines.removeFirst()
                }
            }
            withAnimation(.easeInOut(duration: 0.18)) {
                progress = min(1.0, CGFloat(visibleLines.count) / CGFloat(Self.script.count))
            }
        }
        try? await Task.sleep(nanoseconds: 220_000_000)
        withAnimation(.easeOut(duration: 0.2)) { phase = .ready }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        try? await Task.sleep(nanoseconds: 520_000_000)
        onFinish()
    }
}

struct BootLine: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let tint: Tint

    enum Tint {
        case dim, normal, ok, warn

        var color: Color {
            switch self {
            case .dim:    return Theme.faint
            case .normal: return Theme.subtext
            case .ok:     return Theme.accent
            case .warn:   return Theme.warn
            }
        }
    }
}
