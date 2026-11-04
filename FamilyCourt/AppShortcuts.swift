import AppIntents
import CoreSpotlight
import SwiftUI

// MARK: - 단축어가 앱에 남기는 "이리 가 주세요" 메모

enum ShortcutAction: Equatable {
    case file(CaseType)   // 소송 접수 화면 열기
    case summons          // 재판을 기다리는 사건 보기
    case openCase(String) // 사건 하나 열기 (Siri · Spotlight)
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

// MARK: - 사건 (Siri · Spotlight)
//
// 접수한 사건을 Spotlight 에 싣는다. 누르면 [법원] 탭에서 그 사건이 열린다.

struct CaseEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("사건", comment: "Siri/Spotlight: one family court case")
    )
    static let defaultQuery = CaseQuery()

    let id: String
    let caseNo: String
    let title: String
    let desc: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(caseNo)")
    }

    init(_ c: CourtCase) {
        id = c.id
        caseNo = c.caseNo
        title = c.title
        desc = c.desc
    }
}

@available(iOS 18.0, *)
extension CaseEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let set = defaultAttributeSet
        set.textContent = desc
        return set
    }
}

struct CaseQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [CaseEntity] {
        let wanted = Set(identifiers)
        return Store.savedCases().filter { wanted.contains($0.id) }.map(CaseEntity.init)
    }

    func entities(matching string: String) async throws -> [CaseEntity] {
        func matches(_ s: String) -> Bool { s.range(of: string, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        return Store.savedCases().filter { matches($0.title) || matches($0.desc) || matches($0.caseNo) }.map(CaseEntity.init)
    }

    func suggestedEntities() async throws -> [CaseEntity] {
        Store.savedCases().map(CaseEntity.init)
    }
}

/// 사건을 연다. Spotlight · Siri 결과를 누르면 여기로 온다.
struct OpenCaseIntent: OpenIntent {
    static let title = LocalizedStringResource("사건 열기", comment: "Siri/Spotlight: open a family court case")
    static let description = IntentDescription(
        LocalizedStringResource("접수한 사건을 열어 재판을 이어 가거나 판결을 봐요.", comment: "Siri: open case description")
    )

    @Parameter(title: LocalizedStringResource("사건", comment: "Siri/Spotlight: one family court case"),
               description: LocalizedStringResource("열어 볼 사건", comment: "Siri: case parameter description"))
    var target: CaseEntity

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        ShortcutRouter.shared.pending = .openCase(target.id)
        return .result()
    }
}

enum CaseIndex {
    /// Spotlight 에 싣는 사건을 지금 것에 맞춘다. 앱을 열 때와 뒤로 보낼 때 부른다.
    static func reindex(_ cases: [CourtCase]) async {
        guard #available(iOS 18.0, *) else { return }
        let index = CSSearchableIndex.default()
        try? await index.deleteAppEntities(ofType: CaseEntity.self)
        try? await index.indexAppEntities(cases.filter { !$0.title.isEmpty }.map(CaseEntity.init))
    }
}

// MARK: - Siri 문구

struct FamilyCourtShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FileCivilCaseIntent(),
            phrases: [
                "\(.applicationName) 재판 신청",
                "\(.applicationName)에서 억울한 일 접수"
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
