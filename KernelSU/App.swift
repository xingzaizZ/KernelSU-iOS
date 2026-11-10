import SwiftUI

@main
struct KernelSUApp: App {
    @StateObject private var state = KernelState.shared

    var body: some Scene {
        WindowGroup {
            BootstrapView()
                .environmentObject(state)
                .preferredColorScheme(.dark)
        }
    }
}

struct BootstrapView: View {
    @State private var booting = true

    var body: some View {
        ZStack {
            RootView()
                .opacity(booting ? 0 : 1)

            if booting {
                BootOverlay {
                    withAnimation(.easeOut(duration: 0.35)) {
                        booting = false
                    }
                }
                .transition(.opacity)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}
