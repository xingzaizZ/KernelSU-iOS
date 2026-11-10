import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var state: KernelState
    @State private var appeared = false
    @State private var scanlineOffset: CGFloat = -1

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                statusCard
                rootBanner
                metricsGrid
                kernelCard
                footerNote
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: false)) {
                scanlineOffset = 2
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("KernelSU")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                Text("iOS · kernel-level privilege manager")
                    .font(Theme.mono(11))
                    .foregroundColor(Theme.faint)
            }
            Spacer()
            KsuAppMark(size: 52)
                .shadow(color: .black.opacity(0.45), radius: 8, y: 3)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
    }

    // MARK: 主状态卡

    private var statusCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x14251C), Color(hex: 0x0F1A22)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.accent.opacity(0.30), lineWidth: 1)

            // 扫描线
            GeometryReader { geo in
                LinearGradient(
                    colors: [.clear, Theme.accent.opacity(0.14), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: geo.size.height * 0.45)
                .offset(y: scanlineOffset * geo.size.height)
                .blur(radius: 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    PulseDot()
                    Text(state.rooted ? "已获取 Root 权限" : "未 Root")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.text)
                    Spacer()
                    Text("WORKING")
                        .font(Theme.mono(9, weight: .bold))
                        .tracking(1.6)
                        .foregroundColor(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(Theme.accent.opacity(0.12))
                        )
                        .overlay(Capsule().stroke(Theme.accent.opacity(0.35), lineWidth: 0.8))
                }

                Divider().overlay(Theme.stroke)

                VStack(spacing: 9) {
                    KVRow(key: "uid / euid", value: "0 / 0 (root)", valueColor: Theme.accent)
                    KVRow(key: "selinux", value: "permissive")
                    KVRow(key: "设备", value: state.deviceModel)
                    KVRow(key: "系统", value: "iOS \(state.iosVersion)")
                }

                HStack(spacing: 8) {
                    StatChip(icon: "lock.open.fill", text: "KernelPatch 已注入", tint: Theme.accent)
                    StatChip(icon: "bolt.fill", text: "SuSFS 1.5.2", tint: Theme.info)
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.97)
    }

    private var rootBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(Theme.accent)
            Text("提权通道已激活 · 无需 magiskd · 无模块加载")
                .font(Theme.mono(11))
                .foregroundColor(Theme.subtext)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.accent.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.accent.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: 指标格

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            MetricTile(title: "已授权应用", value: "3", unit: "个", tint: Theme.accent, icon: "person.badge.key.fill")
            MetricTile(title: "活动模块", value: "0", unit: "个", tint: Theme.faint, icon: "shippingbox.fill")
            MetricTile(title: "被拦截请求", value: "3", unit: "次", tint: Theme.danger, icon: "hand.raised.fill")
            MetricTile(title: "运行时长", value: "72", unit: "小时", tint: Theme.info, icon: "clock.fill")
        }
        .opacity(appeared ? 1 : 0)
    }

    // MARK: 内核信息

    private var kernelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "内核信息", trailing: "live")
            KsCard {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(SampleData.kernelInfo.indices, id: \.self) { i in
                        KVRow(key: SampleData.kernelInfo[i].0, value: SampleData.kernelInfo[i].1)
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var footerNote: some View {
        Text("KernelSU iOS Shell · build \(state.managerCode)")
            .font(Theme.mono(10))
            .foregroundColor(Theme.faint.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 6)
    }
}

// MARK: - 组件

struct StatChip: View {
    let icon: String
    let text: String
    var tint: Color = Theme.accent

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold))
            Text(text).font(Theme.mono(10, weight: .medium))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Capsule().fill(tint.opacity(0.10)))
        .overlay(Capsule().stroke(tint.opacity(0.22), lineWidth: 0.8))
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let unit: String
    var tint: Color = Theme.accent
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(tint)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                Text(unit)
                    .font(Theme.mono(10))
                    .foregroundColor(Theme.faint)
            }
            Text(title)
                .font(Theme.mono(10))
                .foregroundColor(Theme.subtext)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.strokeSoft, lineWidth: 1)
        )
    }
}


