import SwiftUI
import UIKit

struct RootView: View {
    @State private var tab: Tab = .home

    enum Tab: String, CaseIterable, Identifiable {
        case home = "首页"
        case superuser = "超级用户"
        case modules = "模块"
        case terminal = "终端"
        case settings = "设置"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .home:      return "shield.lefthalf.filled"
            case .superuser: return "person.badge.key"
            case .modules:   return "shippingbox"
            case .terminal:  return "terminal"
            case .settings:  return "slider.horizontal.3"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            ZStack {
                HomeView()
                    .opacity(tab == .home ? 1 : 0)
                    .allowsHitTesting(tab == .home)
                SuperUserView()
                    .opacity(tab == .superuser ? 1 : 0)
                    .allowsHitTesting(tab == .superuser)
                ModulesView()
                    .opacity(tab == .modules ? 1 : 0)
                    .allowsHitTesting(tab == .modules)
                TerminalView()
                    .opacity(tab == .terminal ? 1 : 0)
                    .allowsHitTesting(tab == .terminal)
                SettingsView()
                    .opacity(tab == .settings ? 1 : 0)
                    .allowsHitTesting(tab == .settings)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBar(selected: $tab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct TabBar: View {
    @Binding var selected: RootView.Tab
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RootView.Tab.allCases) { item in
                Button {
                    guard selected != item else { return }
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selected = item
                    }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.icon)
                            .font(.system(size: 17, weight: selected == item ? .semibold : .regular))
                            .symbolRenderingMode(.hierarchical)
                        Text(item.rawValue)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .foregroundColor(selected == item ? Theme.accent : Theme.faint)
                    .background {
                        if selected == item {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.accent.opacity(0.10))
                                .matchedGeometryEffect(id: "tab", in: ns)
                                .padding(.horizontal, 8)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 26)
        .background {
            ZStack {
                Theme.bgElevated.opacity(0.98)
                LinearGradient(
                    colors: [Theme.accent.opacity(0.06), .clear],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.strokeSoft).frame(height: 1)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
