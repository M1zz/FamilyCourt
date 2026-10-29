import SwiftUI

// MARK: - 홈 탭에서 이동하는 곳들

enum HomeDest: Hashable {
    case caseDetail(String)
    case summons
    case archive
    case learn
    case laws
}

// MARK: - 홈 (액션 런처)

struct HomeView: View {
    @EnvironmentObject var store: Store
    @Binding var path: NavigationPath
    @State private var filingType: CaseType?
    @ObservedObject private var router = ShortcutRouter.shared
    @Environment(\.dynamicTypeSize) private var typeSize

    /// 타일 두 개씩 한 줄 — 아주 큰 글씨에서는 한 줄에 하나씩, 화면을 넘치면 스크롤
    private var row: AnyLayout {
        typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
    }

    var body: some View {
        tiles
        .scrollIfNeeded()
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(router.$pending) { action in
            guard let action else { return }
            // 다른 구독자(ContentView 의 탭 전환)도 같은 값을 받은 뒤에 비운다.
            DispatchQueue.main.async { router.pending = nil }
            switch action {
            case .file(let type):
                filingType = type
            case .summons:
                filingType = nil
                path = NavigationPath()
                path.append(HomeDest.summons)
            }
        }
        #if DEBUG
        .onAppear { if ScreenshotScene.current == .filing { filingType = .civil } }
        #endif
        .sheet(item: $filingType) { type in
            FilingView(type: type) { newId in
                path.append(HomeDest.caseDetail(newId))
            }
        }
    }

    private var tiles: some View {
        VStack(spacing: 12) {
            row {
                Button { filingType = .civil } label: {
                    ActionTile(emoji: "😤", title: store.vocab.civilTileTitle,
                               subtitle: store.vocab.civilTileSub,
                               gradient: [Color(red: 0, green: 0.48, blue: 1), Color(red: 0.35, green: 0.34, blue: 0.84)])
                }
                Button { filingType = .criminal } label: {
                    ActionTile(emoji: "🚨", title: store.vocab.criminalTileTitle,
                               subtitle: store.vocab.criminalTileSub,
                               gradient: [Color(red: 1, green: 0.23, blue: 0.19), Color(red: 1, green: 0.58, blue: 0)])
                }
            }
            row {
                NavigationLink(value: HomeDest.summons) {
                    ActionTile(emoji: "📨", title: store.vocab.summonsTileTitle,
                               subtitle: store.vocab.summonsTileSub(store.openCases.count),
                               badge: store.openCases.count)
                }
                NavigationLink(value: HomeDest.archive) {
                    ActionTile(emoji: "📚", title: store.vocab.archiveTileTitle,
                               subtitle: store.vocab.archiveTileSub(store.doneCases.count))
                }
            }
            row {
                NavigationLink(value: HomeDest.learn) {
                    ActionTile(emoji: "🎓", title: String(localized: "법원 공부하기"),
                               subtitle: String(localized: "역할과 재판 순서 배우기"))
                }
                NavigationLink(value: HomeDest.laws) {
                    ActionTile(emoji: "📜", title: store.vocab.lawsTileTitle,
                               subtitle: store.vocab.lawsTileSub)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ActionTile: View {
    let emoji: String
    let title: String
    let subtitle: String
    var gradient: [Color]? = nil
    var badge: Int = 0
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(emoji).scaledFont(30, relativeTo: .largeTitle)
                .accessibilityHidden(true)
            Spacer(minLength: 4)
            Text(title)
                .scaledFont(16, weight: .bold, relativeTo: .callout)
                .foregroundColor(gradient == nil ? .primary : .white)
                .minimumScaleFactor(0.8)
                .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
            Text(subtitle)
                .scaledFont(12, relativeTo: .caption)
                .foregroundColor(gradient == nil ? .secondary : .white.opacity(0.88))
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
        .background(
            Group {
                if let g = gradient {
                    LinearGradient(colors: g, startPoint: .topLeading, endPoint: .bottomTrailing)
                        // '대비 증가'에서는 흰 글씨가 또렷하도록 바탕을 한 톤 눌러 준다
                        .overlay(Color.black.opacity(contrast == .increased ? 0.3 : 0))
                } else {
                    Color(.secondarySystemGroupedBackground)
                }
            }
        )
        .cornerRadius(16)
        .overlay(alignment: .topTrailing) {
            if badge > 0 {
                Text(verbatim: "\(badge)")
                    .scaledFont(13, weight: .bold, relativeTo: .footnote)
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .frame(minWidth: 22, minHeight: 22)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .padding(10)
            }
        }
        .accessibilityElement(children: .combine)
        // 음성 명령은 타일 제목만 말해도 누를 수 있게
        .accessibilityInputLabels([Text(verbatim: title)])
    }
}

// MARK: - 사건 한 줄 (목록용)

struct CaseRow: View {
    @EnvironmentObject var store: Store
    let courtCase: CourtCase

    var body: some View {
        HStack(spacing: 12) {
            Text(courtCase.type.badgeEmoji).scaledFont(28, relativeTo: .largeTitle)
                .accessibilityLabel(store.vocab.typeName(courtCase.type))
            VStack(alignment: .leading, spacing: 2) {
                Text(courtCase.title)
                    .scaledFont(16, weight: .semibold, relativeTo: .callout)
                    .lineLimit(1)
                Text(String(localized: "\(courtCase.caseNo) · \(store.memName(courtCase.roles.accuser)) vs \(store.memName(courtCase.roles.accused))", comment: "Case row: case number, plaintiff vs defendant"))
                    .scaledFont(13, relativeTo: .footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            StatusBadge(courtCase: courtCase)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

struct StatusBadge: View {
    @EnvironmentObject var store: Store
    let courtCase: CourtCase

    var body: some View {
        let color: Color = {
            switch courtCase.status {
            case .decided:
                if let v = courtCase.verdict, !v.penalty.isEmpty, !v.penaltyDone { return .orange }
                return .green
            case .inTrial: return .orange
            case .waiting: return .blue
            }
        }()
        Text(store.vocab.statusText(courtCase))
            .scaledFont(12, weight: .semibold, relativeTo: .caption)
            .foregroundColor(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }
}

// MARK: - 소환 요청 (재판을 기다리는 사건)

struct SummonsView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        List {
            if store.openCases.isEmpty {
                EmptyNotice(emoji: "🕊️", text: String(localized: "재판을 기다리는 사건이 없어요.\n평화로운 우리 집!"))
            } else {
                Section(footer: Text("소환된 가족은 모두 모여 재판을 열어 주세요!")) {
                    ForEach(store.openCases) { c in
                        NavigationLink(value: HomeDest.caseDetail(c.id)) {
                            CaseRow(courtCase: c)
                        }
                    }
                }
            }
        }
        .navigationTitle(store.vocab.summonsTileTitle)
    }
}

// MARK: - 판례 (끝난 사건)

struct ArchiveView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        List {
            if store.doneCases.isEmpty {
                EmptyNotice(emoji: "📚", text: String(localized: "아직 끝난 사건이 없어요."))
            } else {
                Section(footer: Text("기록이 쌓이면 우리 집 판례가 됩니다!")) {
                    ForEach(store.doneCases) { c in
                        NavigationLink(value: HomeDest.caseDetail(c.id)) {
                            CaseRow(courtCase: c)
                        }
                    }
                }
            }
        }
        .navigationTitle("우리 집 판례")
    }
}

struct EmptyNotice: View {
    let emoji: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji).scaledFont(38, relativeTo: .largeTitle)
                .accessibilityHidden(true)
            Text(text)
                .scaledFont(15, relativeTo: .subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .listRowBackground(Color.clear)
    }
}
