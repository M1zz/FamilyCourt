import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

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
            .fullScreenCover(isPresented: $showOnboarding) {
                FamilyCourtOnboardingView {
                    hasSeenOnboarding = true
                    showOnboarding = false
                }
            }
    }

    private var tabs: some View {
        TabView {
            HomeTab()
                .tabItem { Label("법원", systemImage: "building.columns.fill") }
            NavigationStack { LawsView() }
                .tabItem { Label("법전", systemImage: "book.closed.fill") }
            NavigationStack { FamilyView() }
                .tabItem { Label("가족", systemImage: "person.3.fill") }
            NavigationStack { SettingsView() }
                .tabItem { Label("설정", systemImage: "gearshape.fill") }
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
