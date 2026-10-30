import SwiftUI
import LeeoKit

struct ContentView: View {
    @EnvironmentObject var store: Store
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    @ObservedObject private var router = ShortcutRouter.shared
    @State private var tab = 0

    var body: some View {
        tabs
            .onAppear {
                guard !hasSeenOnboarding else { return }
                // 이미 기록이 있는 가족(업데이트로 온 사용자)에게는 안내를 띄우지 않는다.
                if !store.data.members.isEmpty || !store.data.cases.isEmpty {
                    hasSeenOnboarding = true
                } else {
                    showOnboarding = true
                }
            }
            // 단축어로 열리면 [법원] 탭으로 — 접수·소환 화면은 HomeView 가 연다.
            .onReceive(router.$pending) { action in
                if action != nil { tab = 0 }
            }
            #if DEBUG
            .onAppear { if ScreenshotScene.current == .laws { tab = 1 } }
            #endif
            .fullScreenCover(isPresented: $showOnboarding) {
                FamilyCourtOnboardingView {
                    hasSeenOnboarding = true
                    showOnboarding = false
                }
                .foldConfined()
            }
    }

    private var tabs: some View {
        // 아이폰 듀오를 펴면 탭마다 왼쪽(세로면 아래)은 그 탭, 오른쪽(위)은 재판을 기다리는 사건이다.
        // 접혀 있거나 보통 아이폰이면 탭만 그린다. 지금 화면 그대로다.
        TabView(selection: $tab) {
            HomeTab()
                .foldWithOpenCases()
                .tabItem { Label("법원", systemImage: "building.columns.fill") }
                .tag(0)
            NavigationStack { LawsView() }
                .foldWithOpenCases()
                .tabItem { Label("법전", systemImage: "book.closed.fill") }
                .tag(1)
            NavigationStack { FamilyView() }
                .foldWithOpenCases()
                .tabItem { Label("가족", systemImage: "person.3.fill") }
                .tag(2)
            NavigationStack { SettingsView() }
                .foldWithOpenCases()
                .tabItem { Label("설정", systemImage: "gearshape.fill") }
                .tag(3)
        }
        // 펴면 시스템 탭바 대신 고르는 쪽 판 바닥에 막대가 선다 (가로로 펴면 시스템 탭바가 접힌 선을 가로지른다).
        .foldTabBar(items: [
            .init(value: 0, title: String(localized: "법원"), symbol: "building.columns.fill"),
            .init(value: 1, title: String(localized: "법전"), symbol: "book.closed.fill"),
            .init(value: 2, title: String(localized: "가족"), symbol: "person.3.fill"),
            .init(value: 3, title: String(localized: "설정"), symbol: "gearshape.fill"),
        ], selected: tab) { tab = $0 }
    }
}

// MARK: - 아이폰 듀오 (LeeoKit Fold)

private extension View {
    /// 탭 하나를 접힌 선 양쪽으로 나눈다. 왼쪽(아래)은 이 탭, 오른쪽(위)은 재판을 기다리는 사건.
    func foldWithOpenCases() -> some View {
        FoldSplitView { self } result: { FoldOpenCasesPane() }
            .foldTabBarRoom()
    }
}

/// 펼친 화면의 결과 쪽: 소환 요청 목록. 사건을 누르면 이 판 안에서 그 사건이 열린다.
private struct FoldOpenCasesPane: View {
    var body: some View {
        NavigationStack {
            SummonsView()
                .navigationDestination(for: HomeDest.self) { $0.screen }
        }
        .environment(\.foldLayout, .single)
    }
}

/// 법원 탭 — 홈 런처에서 접수·소환·판례·공부·사건 화면으로 이동해요.
struct HomeTab: View {
    @State private var path = NavigationPath()
    #if DEBUG
    @EnvironmentObject private var store: Store
    #endif

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: HomeDest.self) { $0.screen }
        }
        #if DEBUG
        .onAppear {
            switch ScreenshotScene.current {
            case .learn: path.append(HomeDest.learn)
            case .trial, .verdict, .caseTop:
                if let id = ScreenshotScene.caseId ?? store.data.cases.first?.id {
                    path.append(HomeDest.caseDetail(id))
                }
            default: break
            }
        }
        #endif
    }
}

#if DEBUG
/// 스토어 스크린샷 촬영용 — 실행 인자 `-FCScene <장면>` 으로 바로 그 화면을 연다 (디버그 빌드 전용).
/// 기록은 촬영 스크립트가 Documents/familycourt.json 에 미리 넣어 둔다.
enum ScreenshotScene: String {
    case home, filing, trial, verdict, caseTop, laws, learn

    static var current: ScreenshotScene? {
        UserDefaults.standard.string(forKey: "FCScene").flatMap(ScreenshotScene.init(rawValue:))
    }
    static var caseId: String? { UserDefaults.standard.string(forKey: "FCCase") }
    static func arg(_ key: String) -> String? { UserDefaults.standard.string(forKey: key) }
}
#endif
