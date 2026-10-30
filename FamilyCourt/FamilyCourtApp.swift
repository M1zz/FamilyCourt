import SwiftUI
import UIKit
import LeeoKit
import TipKit

@main
struct FamilyCourtApp: App {
    @StateObject private var store = Store()

    init() {
        // 사용량 기록 · 익명 사용 통계 · 원격 킬스위치 갱신 (FeedbackHub).
        // 크래시 진단은 킬스위치로 끌 수 있게 아래에서 따로 켠다.
        LeeoKit.bootstrap(FamilyCourtSpec.self, flags: FamilyCourtFlag.self, diagnostics: false)
        LeeoDiagnostics.shared.start(
            spec: FamilyCourtSpec.self,
            isEnabled: { LeeoRemoteFlags.isEnabled(FamilyCourtFlag.diagnosticsEnabled) }
        )

        // 사용 팁 (FeatureTips.swift) — 표시 빈도는 TipKit 이 관리한다.
        #if DEBUG
        // 스토어 스크린샷 촬영 중에는 팁 풍선을 띄우지 않는다.
        if ScreenshotScene.current != nil { Tips.hideAllTipsForTesting() }
        #endif
        try? Tips.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                // 아이폰 듀오: 창 크기로 접힘을 재서 아래로 흘린다. 시트 · 알림창도 접힌 선을 비킨다 (LeeoKit Fold).
                .foldAware()
                .onAppear { UIApplication.shared.installKeyboardDismissTap() }
                .modifier(SatisfactionCheckIfEnabled())
                // 팁 상품을 불러오고 끝나지 않은 팁을 마저 센다.
                .task { await FamilyCourtSpec.tipJar.startStandalone() }
        }
    }
}

/// 만족도 질문 — 원격 킬스위치로 끌 수 있다. 플래그는 실행 중 캐시 값이라 화면이 흔들리지 않는다.
private struct SatisfactionCheckIfEnabled: ViewModifier {
    #if DEBUG
    // 스토어 스크린샷 촬영 중에는 묻지 않는다.
    private let enabled = ScreenshotScene.current == nil
        && LeeoRemoteFlags.isEnabled(FamilyCourtFlag.satisfactionPromptEnabled)
    #else
    private let enabled = LeeoRemoteFlags.isEnabled(FamilyCourtFlag.satisfactionPromptEnabled)
    #endif

    func body(content: Content) -> some View {
        if enabled {
            content.leeoSatisfactionCheck(FamilyCourtSpec.self)
        } else {
            content
        }
    }
}

// MARK: - 아무 곳이나 누르면 키보드 내리기

extension UIApplication {
    func installKeyboardDismissTap() {
        guard let window = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }
        let name = "keyboardDismissTap"
        guard window.gestureRecognizers?.contains(where: { $0.name == name }) != true else { return }
        let tap = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tap.name = name
        tap.cancelsTouchesInView = false   // 버튼 등 다른 터치는 그대로 동작해요
        tap.delegate = KeyboardDismissDelegate.shared
        window.addGestureRecognizer(tap)
    }
}

private final class KeyboardDismissDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissDelegate()
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}
