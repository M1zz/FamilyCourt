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

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
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
            HStack(spacing: 12) {
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
            HStack(spacing: 12) {
                NavigationLink(value: HomeDest.learn) {
                    ActionTile(emoji: "🎓", title: "법원 공부하기",
                               subtitle: "역할과 재판 순서 배우기")
                }
                NavigationLink(value: HomeDest.laws) {
                    ActionTile(emoji: "📜", title: store.vocab.lawsTileTitle,
                               subtitle: store.vocab.lawsTileSub)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $filingType) { type in
            FilingView(type: type) { newId in
                path.append(HomeDest.caseDetail(newId))
            }
        }
    }
}

struct ActionTile: View {
    let emoji: String
    let title: String
    let subtitle: String
    var gradient: [Color]? = nil
    var badge: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(emoji).font(.system(size: 30))
            Spacer(minLength: 4)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(gradient == nil ? .primary : .white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(subtitle)
                .font(.system(size: 12))
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
                } else {
                    Color(.secondarySystemGroupedBackground)
                }
            }
        )
        .cornerRadius(16)
        .overlay(alignment: .topTrailing) {
            if badge > 0 {
                Text("\(badge)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .frame(minWidth: 22, minHeight: 22)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .padding(10)
            }
        }
    }
}

// MARK: - 사건 한 줄 (목록용)

struct CaseRow: View {
    @EnvironmentObject var store: Store
    let courtCase: CourtCase

    var body: some View {
        HStack(spacing: 12) {
            Text(courtCase.type.badgeEmoji).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(courtCase.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                Text("\(courtCase.caseNo) · \(store.memName(courtCase.roles.accuser)) vs \(store.memName(courtCase.roles.accused))")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            StatusBadge(courtCase: courtCase)
        }
        .padding(.vertical, 2)
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
            .font(.system(size: 12, weight: .semibold))
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
                EmptyNotice(emoji: "🕊️", text: "재판을 기다리는 사건이 없어요.\n평화로운 우리 집!")
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
                EmptyNotice(emoji: "📚", text: "아직 끝난 사건이 없어요.")
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
            Text(emoji).font(.system(size: 38))
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .listRowBackground(Color.clear)
    }
}
