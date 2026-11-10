import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var state: KernelState
    @State private var showAbout = false
    @State private var showReset = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    group("挂载") {
                        mountPicker
                    }

                    group("开关") {
                        toggleRow("安全模式", subtitle: "跳过所有 hook，仅保留基础提权",
                                  isOn: $state.safeMode)
                        divider
                        toggleRow("详细日志", subtitle: "记录每次 su 调用与返回码",
                                  isOn: $state.loggingEnabled)
                    }

                    group("路径") {
                        KVRow(key: "rootfs", value: "/")
                        divider
                        KVRow(key: "jbroot", value: state.jbPath)
                        divider
                        KVRow(key: "ksud", value: "/var/jb/usr/bin/ksud")
                        divider
                        KVRow(key: "工作目录", value: "/var/jb")
                    }

                    group("关于") {
                        Button { showAbout = true } label: {
                            navRow("版本信息", value: "v\(state.managerVersion) (\(state.managerCode))")
                        }
                        .buttonStyle(.plain)
                        divider
                        Button { showReset = true } label: {
                            navRow("重置所有授权", value: "", tint: Theme.danger)
                        }
                        .buttonStyle(.plain)
                    }

                    footer
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 120)
            }
        }
        .alert("版本信息", isPresented: $showAbout) {
            Button("好", role: .cancel) {}
        } message: {
            Text("""
            KernelSU iOS Shell
            版本 v\(state.managerVersion) (\(state.managerCode))
            内核 \(state.kernelVersion)
            SuSFS \(state.susfsVersion)

            本构建为界面展示外壳：
            不包含模块加载器，不能刷入或启用任何模块。
            """)
        }
        .alert("重置授权？", isPresented: $showReset) {
            Button("取消", role: .cancel) {}
            Button("重置", role: .destructive) {}
        } message: {
            Text("将清空所有应用的 su 授权记录（演示外壳中此操作不会真正执行）。")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("设置")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Theme.text)
            Text("运行参数与路径")
                .font(Theme.mono(10))
                .foregroundColor(Theme.faint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var mountPicker: some View {
        VStack(spacing: 8) {
            ForEach(KernelState.MountMode.allCases) { mode in
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        state.mountMode = mode
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: state.mountMode == mode
                              ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 14))
                            .foregroundColor(state.mountMode == mode ? Theme.accent : Theme.faint)
                        Text(mode.rawValue)
                            .font(Theme.mono(12))
                            .foregroundColor(state.mountMode == mode ? Theme.text : Theme.subtext)
                        Spacer()
                        if mode == .none {
                            Text("禁用模块")
                                .font(Theme.mono(9))
                                .foregroundColor(Theme.faint)
                        }
                    }
                    .padding(.vertical, 3)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func group<C: View>(_ title: String, @ViewBuilder content: @escaping () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: title)
            KsCard(padding: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    content()
                }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.strokeSoft)
            .frame(height: 1)
    }

    private func toggleRow(_ title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.mono(12.5))
                    .foregroundColor(Theme.text)
                Text(subtitle)
                    .font(Theme.mono(9.5))
                    .foregroundColor(Theme.faint)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.accentDeep)
                .scaleEffect(0.85)
        }
    }

    private func navRow(_ title: String, value: String, tint: Color = Theme.text) -> some View {
        HStack {
            Text(title)
                .font(Theme.mono(12.5))
                .foregroundColor(tint)
            Spacer()
            Text(value)
                .font(Theme.mono(10))
                .foregroundColor(Theme.faint)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.faint)
        }
        .contentShape(Rectangle())
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("KernelSU iOS Shell")
                .font(Theme.mono(10, weight: .medium))
                .foregroundColor(Theme.faint)
            Text("界面外壳 · 不含模块引擎")
                .font(Theme.mono(9))
                .foregroundColor(Theme.faint.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}
