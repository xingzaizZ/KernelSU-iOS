import SwiftUI
import UIKit

/// 内置命令解释器：全部为本地字符串模拟，不启动任何进程、不读取系统文件。
struct ShellSimulator {
    static let host = "iPhone"
    static let user = "root"

    static func run(_ raw: String) -> [TerminalLine] {
        let cmd = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return [] }
        var out: [TerminalLine] = []
        let parts = cmd.split(separator: " ").map(String.init)
        let head = parts.first?.lowercased() ?? ""

        switch head {
        case "help", "?":
            out.append(.init(prompt: "", text: """
            可用命令（模拟）:
              id | whoami | su | uname -a | hostname
              ls [path] | cat /proc/version | mount | ps
              ksu --version | ksu status | clear | help
            """, style: .note))

        case "id":
            out.append(.init(prompt: "", text: "uid=0(root) gid=0(wheel) groups=0(wheel),1(daemon),2(kmem),3(sys),4(tty),5(operator),20(staff),80(admin)", style: .output))

        case "whoami":
            out.append(.init(prompt: "", text: "root", style: .output))

        case "su":
            out.append(.init(prompt: "", text: "已处于 root 上下文（uid=0），无需切换。", style: .note))

        case "uname":
            out.append(.init(prompt: "", text: "Darwin \(host) 24.1.0 Darwin Kernel Version 24.1.0: ksu-ios arm64e", style: .output))

        case "hostname":
            out.append(.init(prompt: "", text: host, style: .output))

        case "ls":
            let path = parts.count > 1 ? parts[1] : "/var/jb"
            if path.hasPrefix("/var/jb") {
                out.append(.init(prompt: "", text: """
                drwxr-xr-x  12 root  wheel   384 Nov  1 09:02 Applications
                drwxr-xr-x   8 root  wheel   256 Nov  1 09:02 Library
                drwxr-xr-x  22 root  wheel   704 Nov  1 09:02 usr
                drwxr-xr-x   6 root  wheel   192 Nov  1 09:02 bin
                drwxr-xr-x   4 root  wheel   128 Nov  1 09:02 etc
                """, style: .output))
            } else if path == "/" || path == "/var" {
                out.append(.init(prompt: "", text: """
                drwxr-xr-x  20 root  wheel   640 Nov  1 09:02 .
                drwxr-xr-x  20 root  wheel   640 Nov  1 09:02 ..
                drwxr-xr-x   2 root  wheel    64 Nov  1 09:02 Applications
                drwxr-xr-x  64 root  wheel  2048 Nov  1 09:02 System
                drwxr-xr-x   6 root  wheel   192 Nov  1 09:02 private
                drwxr-xr-x   4 root  wheel   128 Nov  1 09:02 var
                """, style: .output))
            } else {
                out.append(.init(prompt: "", text: "ls: \(path): No such file or directory", style: .error))
            }

        case "cat":
            let path = parts.count > 1 ? parts[1] : ""
            if path == "/proc/version" {
                out.append(.init(prompt: "", text: "Darwin Kernel Version 24.1.0 ksu-ios #1 SMP PREEMPT arm64e", style: .output))
            } else if path == "/proc/uid" {
                out.append(.init(prompt: "", text: "0", style: .output))
            } else {
                out.append(.init(prompt: "", text: "cat: \(path.isEmpty ? "missing operand" : path + ": No such file or directory")", style: .error))
            }

        case "mount":
            out.append(.init(prompt: "", text: """
            /dev/disk1s1 on / (apfs, local, read-only, journaled)
            devfs on /dev (devfs, local)
            overlay on /var/jb (overlayfs, local, rw)  [ksu]
            """, style: .output))

        case "ps":
            out.append(.init(prompt: "", text: """
              PID TTY      TIME     CMD
                1 ??       0:00.42 launchd
              412 ??       0:00.06 kernelmanagerd
              418 ttys000  0:00.01 sh
              419 ttys000  0:00.00 ksu --shell
            """, style: .output))

        case "ksu":
            let sub = parts.count > 1 ? parts[1] : ""
            if sub == "--version" || sub == "-v" {
                out.append(.init(prompt: "", text: "KernelSU v1.0.0-ios (1024) — shell build", style: .output))
            } else if sub == "status" {
                out.append(.init(prompt: "", text: """
                kernel:    loaded (arm64e)
                kpatch:    active
                manager:   1.0.0 (1024)
                modules:   disabled in this build
                """, style: .output))
            } else {
                out.append(.init(prompt: "", text: "usage: ksu [--version|status]", style: .note))
            }

        case "clear":
            out.append(.init(prompt: "", text: "__CLEAR__", style: .note))

        case "sudo", "exit", "reboot", "shutdown", "rm", "dd", "killall":
            out.append(.init(prompt: "", text: "本构建为只读展示外壳，该命令未启用。", style: .error))

        default:
            out.append(.init(prompt: "", text: "sh: \(head): command not found", style: .error))
        }

        return out
    }
}

struct TerminalView: View {
    @State private var lines: [TerminalLine] = [
        .init(prompt: "", text: "KernelSU shell (simulated) · uid=0(root)", style: .note),
        .init(prompt: "", text: "输入 help 查看可用命令", style: .note)
    ]
    @State private var input = ""
    @FocusState private var focused: Bool
    var body: some View {
        VStack(spacing: 0) {
            header
            console
            inputBar
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(Theme.danger.opacity(0.8)).frame(width: 9, height: 9)
                Circle().fill(Theme.warn.opacity(0.8)).frame(width: 9, height: 9)
                Circle().fill(Theme.accent.opacity(0.8)).frame(width: 9, height: 9)
            }
            Spacer()
            Text("root@\(ShellSimulator.host): ~")
                .font(Theme.mono(10))
                .foregroundColor(Theme.faint)
            Spacer()
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    lines = [.init(prompt: "", text: "屏幕已清空", style: .note)]
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.faint)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Theme.bgElevated)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.strokeSoft).frame(height: 1)
        }
    }

    private var console: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(lines) { line in
                        lineView(line).id(line.id)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: lines.count, perform: { _ in
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            })
        }
        .background(Theme.bg)
        .onTapGesture { focused = true }
    }

    @ViewBuilder
    private func lineView(_ line: TerminalLine) -> some View {
        switch line.style {
        case .command:
            HStack(alignment: .top, spacing: 6) {
                Text(line.prompt)
                    .font(Theme.mono(11.5, weight: .semibold))
                    .foregroundColor(Theme.accentDeep)
                Text(line.text)
                    .font(Theme.mono(11.5))
                    .foregroundColor(Theme.accent)
                    .textSelection(.enabled)
            }
        default:
            Text(line.text)
                .font(Theme.mono(11))
                .foregroundColor(line.style.color)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            Text("$")
                .font(Theme.mono(13, weight: .bold))
                .foregroundColor(Theme.accent)
            TextField("", text: $input, prompt: Text("输入命令…").foregroundColor(Theme.faint))
                .font(Theme.mono(12))
                .foregroundColor(Theme.text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focused)
                .onSubmit(execute)
            Button(action: execute) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(input.isEmpty ? Theme.faint : Theme.accent)
            }
            .buttonStyle(.plain)
            .disabled(input.isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            Theme.bgElevated
                .overlay(alignment: .top) {
                    Rectangle().fill(Theme.strokeSoft).frame(height: 1)
                }
        )
    }

    private func execute() {
        let cmd = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }
        input = ""

        withAnimation(.easeOut(duration: 0.12)) {
            lines.append(.init(prompt: "root@\(ShellSimulator.host) ~ %", text: cmd, style: .command))
        }

        let result = ShellSimulator.run(cmd)
        if result.contains(where: { $0.text == "__CLEAR__" }) {
            withAnimation(.easeOut(duration: 0.2)) { lines.removeAll() }
            return
        }
        withAnimation(.easeOut(duration: 0.12)) {
            lines.append(contentsOf: result)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
