import SwiftUI
import LeeoKit

struct ContentView: View {
    @EnvironmentObject var store: Store
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    @ObservedObject private var router = ShortcutRouter.shared
    @State private var tab = 0
    @EnvironmentObject private var pro: LeeoStore
    /// 구독 졸업 제안(어른 확인 뒤).
    @State private var lock: ProLock?

    var body: some View {
        // 넓은 아이패드는 식탁 가운데 놓는 재판정 — 펼친 아이폰 듀오처럼 탭 | 기다리는 사건 두 쪽
        WidePadPanes { tabs }
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
            .task { await offerGraduationIfDue() }
            .unlockSheet($lock)
            .fullScreenCover(isPresented: $showOnboarding) {
                FamilyCourtOnboardingView {
                    hasSeenOnboarding = true
                    showOnboarding = false
                }
                .foldConfined()
            }
    }

    /// 구독 6개월째와 연 갱신 7일 전에 한 번씩 구독 졸업 Pro 평생을 제안한다(→ LeeoGraduation).
    /// 졸업가 상품이 스토어에 서 있을 때만.
    private func offerGraduationIfDue() async {
        guard let subscription = await LeeoGraduation.currentSubscription(among: Pro.subscriptionIDs),
              LeeoGraduation.isDue(subscription, lastOffered: LeeoGraduation.lastOffered()) else { return }
        await pro.loadProducts()
        guard pro.products.contains(where: { $0.id == Pro.graduateID }) else { return }
        LeeoGraduation.markOffered()
        lock = .graduate
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

/// 넓은 아이패드도 가로로 편 아이폰 듀오와 같은 짝으로 세운다: 왼쪽 탭, 오른쪽 재판을 기다리는 사건.
/// 아이패드는 접히지 않아 Fold 가 한 쪽(single)으로 재므로, regular 폭이면 여기서 펼친 자세로 바꿔 흘린다.
/// Slide Over · 좁은 분할(compact)은 아이폰처럼 한 쪽.
private struct WidePadPanes<Content: View>: View {
    @Environment(\.foldLayout) private var fold
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .environment(\.foldLayout, layout)
            .environment(\.isWidePadPanes, layout.isUnfolded && !fold.isUnfolded)
    }

    private var layout: FoldLayout {
        guard UIDevice.current.userInterfaceIdiom == .pad, sizeClass == .regular,
              fold.windowSize != .zero else { return fold }
        return FoldLayout(posture: .innerLandscape, windowSize: fold.windowSize)
    }
}

extension EnvironmentValues {
    /// 넓은 아이패드라서 두 쪽으로 세웠는가(진짜 접는 폰이 아니라).
    @Entry var isWidePadPanes = false
}

extension View {
    /// 화면 전체를 덮는 것에 건다. 펼친 아이폰 듀오에서는 고르는 쪽 판에만 서고(접힌 선을 넘지 않게),
    /// 넓은 아이패드는 접힌 선이 없으니 화면을 다 쓴다(재판은 다 같이 보는 화면이다).
    func coverConfined() -> some View { modifier(CoverConfined()) }
}

private struct CoverConfined: ViewModifier {
    @Environment(\.isWidePadPanes) private var widePad

    func body(content: Content) -> some View {
        if widePad {
            content.environment(\.foldLayout, .single)
        } else {
            content.foldConfined()
        }
    }
}

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
