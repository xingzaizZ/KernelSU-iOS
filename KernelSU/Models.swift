import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - 内核状态（本 App 为展示用外壳，数据在本地生成，不做真实提权）

final class KernelState: ObservableObject {
    static let shared = KernelState()

    @Published var rooted: Bool = true
    @Published var kernelVersion: String = "6.1.0-ksu-ios"
    @Published var susfsVersion: String = "1.5.2 (shell)"
    @Published var managerVersion: String = "1.0.0"
    @Published var managerCode: Int = 1024
    @Published var deviceModel: String = KernelState.hardwareModel()
    @Published var iosVersion: String = UIDevice.current.systemVersion
    @Published var jbPath: String = "/var/jb"
    @Published var mountMode: MountMode = .overlayfs
    @Published var safeMode: Bool = false
    @Published var loggingEnabled: Bool = true

    enum MountMode: String, CaseIterable, Identifiable {
        case overlayfs = "OverlayFS"
        case magicMount = "Magic Mount"
        case none = "未挂载"
        var id: String { rawValue }
    }

    private init() {}

    static func hardwareModel() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        return machine.isEmpty ? "iPhone" : machine
    }
}

// MARK: - 超级用户

struct SuEntry: Identifiable, Hashable {
    let name: String
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let granted: Bool
    let grantTime: String
    let lastRequest: String
    let scope: String
}

struct SuLog: Identifiable, Hashable {
    let id = UUID()
    let time: String
    let app: String
    let command: String
    let result: String
}

struct SuspiciousCall: Identifiable, Hashable {
    let id = UUID()
    let time: String
    let process: String
    let detail: String
}

// MARK: - 模块

struct KernelModule: Identifiable, Hashable {
    let name: String
    var id: String { name }
    let version: String
    let author: String
    let summary: String
    let enabled: Bool
    let size: String
    let installTime: String
    let kind: ModuleKind

    enum ModuleKind: String {
        case system = "系统"
        case tweak  = "Tweak"
        case script = "脚本"
    }
}

// MARK: - 终端

struct TerminalLine: Identifiable, Hashable {
    let id = UUID()
    let prompt: String
    let text: String
    let style: Style

    enum Style {
        case command
        case output
        case error
        case note

        var color: Color {
            switch self {
            case .command: return Theme.accent
            case .output:  return Theme.text
            case .error:   return Theme.danger
            case .note:    return Theme.subtext
            }
        }
    }
}

// MARK: - 静态演示数据

enum SampleData {

    static let superUsers: [SuEntry] = [
        SuEntry(name: "Filza", bundleIdentifier: "com.tigisoftware.filza",
                granted: true, grantTime: "2026-11-02 09:14", lastRequest: "3 分钟前", scope: "全局"),
        SuEntry(name: "Terminal", bundleIdentifier: "com.apple.Terminal",
                granted: true, grantTime: "2026-10-28 21:03", lastRequest: "刚刚", scope: "全局"),
        SuEntry(name: "NewTerm 3", bundleIdentifier: "ws.hbang.newterm3",
                granted: true, grantTime: "2026-10-31 12:40", lastRequest: "1 小时前", scope: "全局"),
        SuEntry(name: "iCleaner Pro", bundleIdentifier: "com.exile90.icleanerpro",
                granted: false, grantTime: "—", lastRequest: "昨天 23:51", scope: "请求被拒"),
        SuEntry(name: "Shortcuts", bundleIdentifier: "com.apple.shortcuts",
                granted: true, grantTime: "2026-11-05 08:22", lastRequest: "12 分钟前", scope: "单次"),
        SuEntry(name: "Shadowrocket", bundleIdentifier: "com.liguangming.Shadowrocket",
                granted: false, grantTime: "—", lastRequest: "2 天前", scope: "从未授权")
    ]

    static let suLogs: [SuLog] = [
        SuLog(time: "21:19:02", app: "Terminal", command: "id -u", result: "0"),
        SuLog(time: "21:18:44", app: "Filza", command: "ls -la /var/jb", result: "ok"),
        SuLog(time: "21:16:30", app: "Shortcuts", command: "whoami", result: "root"),
        SuLog(time: "21:11:09", app: "Terminal", command: "cat /proc/version", result: "ok"),
        SuLog(time: "20:58:12", app: "NewTerm 3", command: "mount | head", result: "ok"),
        SuLog(time: "20:47:51", app: "iCleaner Pro", command: "su -c reboot", result: "denied")
    ]

    static let suspicious: [SuspiciousCall] = [
        SuspiciousCall(time: "19:32:07", process: "unknown_helper", detail: "未签名进程尝试调用 su，已拦截"),
        SuspiciousCall(time: "18:04:55", process: "sysdiagnose", detail: "提权请求来源异常，已记录"),
        SuspiciousCall(time: "17:41:20", process: "WebContent", detail: "沙盒外访问 /var/jb，已阻断")
    ]

    static let modules: [KernelModule] = [
        KernelModule(name: "ksu-ios-hook", version: "2.3.1", author: "tiann",
                     summary: "内核态 syscall hook 基础支撑层", enabled: true,
                     size: "412 KB", installTime: "2026-11-01", kind: .system),
        KernelModule(name: "SystemWide-AdBlock", version: "5.0.2", author: "0x192",
                     summary: "全局 hosts 拦截，覆盖 12.4 万条规则", enabled: true,
                     size: "1.8 MB", installTime: "2026-10-29", kind: .system),
        KernelModule(name: "AudioRecorder-X", version: "1.4.0", author: "akusio",
                     summary: "通话录音与后台音频捕获", enabled: true,
                     size: "768 KB", installTime: "2026-10-27", kind: .tweak),
        KernelModule(name: "BatterySaver+", version: "3.1.7", author: "hackcat",
                     summary: "调度器参数调优，降低待机功耗", enabled: false,
                     size: "96 KB", installTime: "2026-10-24", kind: .script),
        KernelModule(name: "LocationSpoofer", version: "0.9.3", author: "Nyaatrap",
                     summary: "定位注入，支持按 App 白名单", enabled: true,
                     size: "244 KB", installTime: "2026-10-21", kind: .tweak),
        KernelModule(name: "CleanerUI", version: "1.0.0", author: "local",
                     summary: "去除系统 UI 冗余组件", enabled: false,
                     size: "58 KB", installTime: "2026-10-18", kind: .system)
    ]

    static let kernelInfo: [(String, String)] = [
        ("内核版本", "6.1.0-ksu-ios #1 SMP PREEMPT"),
        ("KernelSU", "v1.0.0-ios (1024)"),
        ("SuSFS", "v1.5.2"),
        ("支持架构", "arm64e / arm64"),
        ("KernelPatch", "已加载"),
        ("SELinux", "permissive (演示)")
    ]
}
