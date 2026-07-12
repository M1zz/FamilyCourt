import SwiftUI
import UIKit

@main
struct FamilyCourtApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear { UIApplication.shared.installKeyboardDismissTap() }
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
