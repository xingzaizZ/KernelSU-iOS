import SwiftUI
import UIKit

struct SuperUserView: View {
    @State private var segment: Int = 0
    @State private var apps = SampleData.superUsers
    @State private var query = ""

    private var filtered: [SuEntry] {
        guard !query.isEmpty else { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            segmentBar
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if segment == 0 {
                        searchField
                        ForEach(filtered) { entry in
                            SuEntryRow(entry: entry) { toggle(entry) }
                        }
                        if filtered.isEmpty {
                            emptyHint("没有匹配的应用")
                        }
                    } else if segment == 1 {
                        ForEach(SampleData.suLogs) { log in
                            SuLogRow(log: log)
                        }
                    } else {
                        SectionHeader(title: "可疑提权调用", trailing: "\(SampleData.suspicious.count) 条")
                            .padding(.top, 4)
                        ForEach(SampleData.suspicious) { item in
                            SuspiciousRow(item: item)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("超级用户")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                Text("su 请求授权与审计")
                    .font(Theme.mono(10))
                    .foregroundColor(Theme.faint)
            }
            Spacer()
            Text("\(apps.filter(\.granted).count)/\(apps.count)")
                .font(Theme.mono(12, weight: .semibold))
                .foregroundColor(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private var segmentBar: some View {
        HStack(spacing: 6) {
            ForEach(["应用", "日志", "拦截"].indices, id: \.self) { i in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { segment = i }
                } label: {
                    Text(["应用", "日志", "拦截"][i])
                        .font(Theme.mono(12, weight: segment == i ? .semibold : .regular))
                        .foregroundColor(segment == i ? Theme.bg : Theme.subtext)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(segment == i ? Theme.accent : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.bgElevated)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.faint)
            TextField("", text: $query, prompt: Text("搜索应用或 Bundle ID").foregroundColor(Theme.faint))
                .font(Theme.mono(12))
                .foregroundColor(Theme.text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.faint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Theme.strokeSoft, lineWidth: 1)
        )
    }

    private func toggle(_ entry: SuEntry) {
        guard let idx = apps.firstIndex(of: entry) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.18)) {
            apps[idx] = SuEntry(
                name: entry.name,
                bundleIdentifier: entry.bundleIdentifier,
                granted: !entry.granted,
                grantTime: entry.granted ? "—" : Self.nowString(),
                lastRequest: entry.lastRequest,
                scope: entry.granted ? "已撤销" : "全局"
            )
        }
    }

    private static func nowString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date())
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(Theme.mono(12))
            .foregroundColor(Theme.faint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }
}

// MARK: - 行

struct SuEntryRow: View {
    let entry: SuEntry
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AppGlyph(name: entry.name, granted: entry.granted)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.text)
                Text(entry.bundleIdentifier)
                    .font(Theme.mono(9.5))
                    .foregroundColor(Theme.faint)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 8) {
                    Text(entry.granted ? "已授权" : "未授权")
                        .font(Theme.mono(9, weight: .semibold))
                        .foregroundColor(entry.granted ? Theme.accent : Theme.faint)
                    Text("·")
                        .foregroundColor(Theme.faint)
                    Text("最近 \(entry.lastRequest)")
                        .font(Theme.mono(9))
                        .foregroundColor(Theme.subtext)
                }
                .padding(.top, 1)
            }

            Spacer(minLength: 6)

            Toggle("", isOn: .constant(entry.granted))
                .labelsHidden()
                .tint(Theme.accentDeep)
                .allowsHitTesting(false)
                .scaleEffect(0.82)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(entry.granted ? Theme.accent.opacity(0.20) : Theme.strokeSoft, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

struct AppGlyph: View {
    let name: String
    var granted: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: granted
                            ? [Theme.accent.opacity(0.22), Theme.accentDeep.opacity(0.10)]
                            : [Theme.stroke, Theme.bgElevated],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 38, height: 38)
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(granted ? Theme.accent : Theme.faint)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 0.8)
        )
    }
}

struct SuLogRow: View {
    let log: SuLog
    private var denied: Bool { log.result == "denied" }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(log.time)
                .font(Theme.mono(10))
                .foregroundColor(Theme.faint)
                .frame(width: 58, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(log.app) › \(log.command)")
                    .font(Theme.mono(11.5))
                    .foregroundColor(Theme.text)
                    .lineLimit(2)
                Text(denied ? "拒绝" : "允许")
                    .font(Theme.mono(9, weight: .semibold))
                    .foregroundColor(denied ? Theme.danger : Theme.accent)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.strokeSoft, lineWidth: 1)
        )
    }
}

struct SuspiciousRow: View {
    let item: SuspiciousCall

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.warn)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.process)
                        .font(Theme.mono(11.5, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Text(item.time)
                        .font(Theme.mono(9))
                        .foregroundColor(Theme.faint)
                }
                Text(item.detail)
                    .font(Theme.mono(10))
                    .foregroundColor(Theme.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.warn.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.warn.opacity(0.20), lineWidth: 1)
        )
    }
}
