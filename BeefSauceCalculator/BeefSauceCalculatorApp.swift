import SwiftUI
import UIKit

@main
struct BeefSauceCalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

private struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingSplash = true
    @State private var splashFirstFrameVisible = false
    @State private var splashTimerStarted = false
    @State private var splashTask: Task<Void, Never>?

    var body: some View {
        Group {
            if showingSplash {
                SplashView {
                    handleSplashFirstFrameVisible()
                }
            } else {
                ContentView()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhaseChange(phase)
        }
        .onAppear {
            handleScenePhaseChange(scenePhase)
        }
        .onDisappear {
            cancelSplashTimer()
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        guard showingSplash else { return }

        if phase == .active {
            startSplashTimerIfNeeded()
        } else {
            cancelSplashTimer()
        }
    }

    private func handleSplashFirstFrameVisible() {
        guard showingSplash, !splashFirstFrameVisible else { return }
        splashFirstFrameVisible = true
        if scenePhase == .active {
            startSplashTimerIfNeeded()
        }
    }

    private func startSplashTimerIfNeeded() {
        guard splashFirstFrameVisible, !splashTimerStarted else { return }
        splashTimerStarted = true

        splashTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(1200))
            } catch {
                await MainActor.run {
                    splashTimerStarted = false
                }
                return
            }

            await MainActor.run {
                guard showingSplash else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    showingSplash = false
                }
                splashTask = nil
            }
        }
    }

    private func cancelSplashTimer() {
        splashTask?.cancel()
        splashTask = nil
        splashTimerStarted = false
    }
}

private struct SplashView: View {
    var onFirstFrameVisible: () -> Void

    var body: some View {
        ZStack {
            Image("SplashScreen")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            SplashFirstFrameProbe(onVisible: onFirstFrameVisible)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
    }
}

private struct SplashFirstFrameProbe: UIViewRepresentable {
    var onVisible: () -> Void

    func makeUIView(context: Context) -> ProbeView {
        ProbeView(onVisible: onVisible)
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        uiView.onVisible = onVisible
    }

    final class ProbeView: UIView {
        var onVisible: () -> Void

        private var displayLink: CADisplayLink?
        private var reported = false

        init(onVisible: @escaping () -> Void) {
            self.onVisible = onVisible
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            isHidden = true
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()

            guard window != nil else {
                displayLink?.invalidate()
                displayLink = nil
                return
            }
            guard !reported, displayLink == nil else { return }
            let link = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        @objc private func displayLinkDidFire() {
            displayLink?.invalidate()
            displayLink = nil

            guard !reported else { return }
            reported = true

            DispatchQueue.main.async {
                self.onVisible()
            }
        }
    }
}
