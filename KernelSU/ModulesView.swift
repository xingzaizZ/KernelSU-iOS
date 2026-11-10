import SwiftUI
import UIKit

struct ModulesView: View {
    @State private var modules = SampleData.modules
    @State private var showUnsupported = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    unsupportedBanner

                    SectionHeader(title: "已安装", trailing: "\(modules.count)")
                    ForEach(modules) { m in
                        ModuleRow(module: m) { toggle(m) }
                    }

                    installButton

                    SectionHeader(title: "仓库", trailing: "0")
                        .padding(.top, 6)
                    repoEmpty
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 120)
            }
        }
        .alert("模块功能不可用", isPresented: $showUnsupported) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("本构建为 iOS 展示外壳，不包含模块加载器（magiskd / OverlayFS 后端均未编译）。\n安装与在线仓库功能未实现，仅供界面展示。")
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("模块")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                Text("OverlayFS · 只读展示")
                    .font(Theme.mono(10))
                    .foregroundColor(Theme.faint)
            }
            Spacer()
            Text("\(modules.filter(\.enabled).count) 启用")
                .font(Theme.mono(11, weight: .semibold))
                .foregroundColor(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var unsupportedBanner: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.info)
                .padding(.top, 1)
            Text("当前构建不含模块注入后端，列表中的模块状态仅用于界面演示，不会实际生效。")
                .font(Theme.mono(10.5))
                .foregroundColor(Theme.subtext)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.info.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.info.opacity(0.18), lineWidth: 1)
        )
    }

    private var installButton: some View {
        Button {
            showUnsupported = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("从本地安装模块")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Theme.faint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Theme.bgElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(
                        Theme.stroke,
                        style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    private var repoEmpty: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(Theme.faint)
            Text("未配置模块仓库")
                .font(Theme.mono(11))
                .foregroundColor(Theme.faint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.strokeSoft, lineWidth: 1)
        )
    }

    private func toggle(_ m: KernelModule) {
        guard let idx = modules.firstIndex(of: m) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.18)) {
            let old = modules[idx]
            modules[idx] = KernelModule(
                name: old.name, version: old.version, author: old.author,
                summary: old.summary, enabled: !old.enabled,
                size: old.size, installTime: old.installTime, kind: old.kind
            )
        }
    }
}

struct ModuleRow: View {
    let module: KernelModule
    let onToggle: () -> Void

    private var kindColor: Color {
        switch module.kind {
        case .system: return Theme.info
        case .tweak:  return Theme.accent
        case .script: return Theme.warn
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Text(module.name)
                    .font(Theme.mono(13, weight: .semibold))
                    .foregroundColor(module.enabled ? Theme.text : Theme.subtext)
                Text("v\(module.version)")
                    .font(Theme.mono(9))
                    .foregroundColor(Theme.faint)
                Spacer()
                Toggle("", isOn: .constant(module.enabled))
                    .labelsHidden()
                    .tint(Theme.accentDeep)
                    .allowsHitTesting(false)
                    .scaleEffect(0.78)
            }

            Text(module.summary)
                .font(Theme.mono(10.5))
                .foregroundColor(Theme.subtext)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 7) {
                Text(module.kind.rawValue)
                    .font(Theme.mono(9, weight: .semibold))
                    .foregroundColor(kindColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(RoundedRectangle(cornerRadius: 4).fill(kindColor.opacity(0.12)))
                Text(module.author)
                    .font(Theme.mono(9))
                    .foregroundColor(Theme.faint)
                Text("·")
                    .font(Theme.mono(9))
                    .foregroundColor(Theme.faint)
                Text(module.size)
                    .font(Theme.mono(9))
                    .foregroundColor(Theme.faint)
                Spacer()
                Text(module.installTime)
                    .font(Theme.mono(9))
                    .foregroundColor(Theme.faint)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(module.enabled ? Theme.stroke : Theme.strokeSoft, lineWidth: 1)
        )
        .opacity(module.enabled ? 1 : 0.65)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}
