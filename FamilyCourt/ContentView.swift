import SwiftUI

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
            .fullScreenCover(isPresented: $showOnboarding) {
                FamilyCourtOnboardingView {
                    hasSeenOnboarding = true
                    showOnboarding = false
                }
            }
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            HomeTab()
                .tabItem { Label("법원", systemImage: "building.columns.fill") }
                .tag(0)
            NavigationStack { LawsView() }
                .tabItem { Label("법전", systemImage: "book.closed.fill") }
                .tag(1)
            NavigationStack { FamilyView() }
                .tabItem { Label("가족", systemImage: "person.3.fill") }
                .tag(2)
            NavigationStack { SettingsView() }
                .tabItem { Label("설정", systemImage: "gearshape.fill") }
                .tag(3)
        }
    }
}

/// 법원 탭 — 홈 런처에서 접수·소환·판례·공부·사건 화면으로 이동해요.
struct HomeTab: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: HomeDest.self) { dest in
                    switch dest {
                    case .caseDetail(let id): CaseDetailView(caseId: id)
                    case .summons: SummonsView()
                    case .archive: ArchiveView()
                    case .learn: LearnView()
                    case .laws: LawsView()
                    }
                }
        }
    }
}
