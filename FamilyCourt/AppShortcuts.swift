import AppIntents
import SwiftUI

// MARK: - 단축어가 앱에 남기는 "이리 가 주세요" 메모

enum ShortcutAction: Equatable {
    case file(CaseType)   // 소송 접수 화면 열기
    case summons          // 재판을 기다리는 사건 보기
}

/// 단축어(App Intents)가 앱을 연 뒤 어느 화면으로 갈지 전한다.
/// ContentView 는 [법원] 탭으로 옮기고, HomeView 가 접수 시트나 소환 목록을 연다.
@MainActor
final class ShortcutRouter: ObservableObject {
    static let shared = ShortcutRouter()
    @Published var pending: ShortcutAction?
}

// MARK: - 단축어

struct FileCivilCaseIntent: AppIntent {
    static var title: LocalizedStringResource = "억울한 일 접수하기"
    static var description = IntentDescription("억울한 일을 민사 소송으로 접수하는 화면을 열어요.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        ShortcutRouter.shared.pending = .file(.civil)
        return .result()
    }
}

struct FileCriminalCaseIntent: AppIntent {
    static var title: LocalizedStringResource = "약속 어김 신고하기"
    static var description = IntentDescription("우리 집 법을 어긴 일을 형사 소송으로 접수하는 화면을 열어요.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        ShortcutRouter.shared.pending = .file(.criminal)
        return .result()
    }
}

struct OpenSummonsIntent: AppIntent {
    static var title: LocalizedStringResource = "기다리는 재판 보기"
    static var description = IntentDescription("아직 재판을 열지 않은 사건 목록을 보여 줘요.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        ShortcutRouter.shared.pending = .summons
        return .result()
    }
}

struct FamilyCourtShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FileCivilCaseIntent(),
            phrases: [
                "\(.applicationName) 재판 신청",
                "\(.applicationName)에서 억울한 일 접수",
                "\(.applicationName) 억울한 일 접수하기"
            ],
            shortTitle: "억울한 일 접수",
            systemImageName: "exclamationmark.bubble"
        )
        AppShortcut(
            intent: FileCriminalCaseIntent(),
            phrases: [
                "\(.applicationName) 약속 어김 신고",
                "\(.applicationName)에서 법 어긴 일 신고"
            ],
            shortTitle: "약속 어김 신고",
            systemImageName: "light.beacon.max"
        )
        AppShortcut(
            intent: OpenSummonsIntent(),
            phrases: [
                "\(.applicationName) 기다리는 재판 보기",
                "\(.applicationName)에서 소환 확인"
            ],
            shortTitle: "기다리는 재판",
            systemImageName: "envelope.badge"
        )
    }
}
