import SwiftUI

/// 사건 허브 — 한 사건의 접수 → 재판 → 판결 → 약속을 이 화면에서 끝까지 보조해요.
struct CaseDetailView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    let caseId: String
    @State private var showTrial = false
    @State private var confirmDelete = false

    var body: some View {
        if let c = store.courtCase(caseId) {
            List {
                headerSection(c)
                rolesSection(c)
                contentSection(c)
                if let v = c.verdict { verdictSection(c, v) }
                actionSection(c)
            }
            .navigationTitle(c.caseNo)
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showTrial) {
                TrialFlowView(caseId: caseId)
            }
            .confirmationDialog("이 사건을 삭제할까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("삭제하기", role: .destructive) {
                    store.deleteCase(caseId)
                    dismiss()
                }
            }
        } else {
            Text("사건을 찾을 수 없어요")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 개요 + 진행 단계

    private func headerSection(_ c: CourtCase) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("\(c.caseNo) · \(c.createdAt)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TypeBadge(type: c.type)
                    StatusBadge(courtCase: c)
                }
                Text(c.title)
                    .font(.title3.bold())
                StepTrack(current: progress(c))
                Text(nextTodo(c))
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.blue.opacity(0.12))
                    .cornerRadius(10)
            }
            .padding(.vertical, 4)
        }
    }

    private func progress(_ c: CourtCase) -> Int {
        // 단계: 0 접수 → 1 재판 → 2 판결 → 3 약속 (4 = 모두 끝)
        guard c.status == .decided else { return 1 }
        if let v = c.verdict, !v.penalty.isEmpty, !v.penaltyDone { return 3 }
        return 4
    }

    private func nextTodo(_ c: CourtCase) -> String {
        let v = store.vocab
        switch c.status {
        case .waiting:
            return "👉 다음 할 일: 가족을 모아 재판을 열어요. \(v.judge) \(store.memName(c.roles.judge)) 님이 진행해요."
        case .inTrial:
            return "👉 재판이 진행 중이에요. 이어서 진행해 주세요!"
        case .decided:
            if let verdict = c.verdict, !verdict.penalty.isEmpty, !verdict.penaltyDone {
                return "👉 다음 할 일: \(store.memName(c.roles.accused)) 님이 약속을 지키면 아래에 체크해요."
            }
            return "🎉 이 사건은 모두 끝났어요. 서로 안아주고 화해했나요?"
        }
    }

    // MARK: - 역할

    private func rolesSection(_ c: CourtCase) -> some View {
        let v = store.vocab
        return Section(header: Text("이 사건의 역할 — \(v.ga(v.accuser(c.type))) 정했어요")) {
            RoleRow(role: "👨‍⚖️ \(v.judge)", name: store.memName(c.roles.judge))
            RoleRow(role: "\(c.type.accuserEmoji) \(v.accuser(c.type))", name: store.memName(c.roles.accuser))
            RoleRow(role: "\(c.type.accusedEmoji) \(v.accused(c.type))", name: store.memName(c.roles.accused))
            if !c.roles.lawyer.isEmpty {
                RoleRow(role: "🛡️ \(v.lawyer)", name: store.memName(c.roles.lawyer))
            }
            if !c.roles.clerk.isEmpty {
                RoleRow(role: "✍️ \(v.clerk)", name: store.memName(c.roles.clerk))
            }
        }
    }

    // MARK: - 사건 내용

    private func contentSection(_ c: CourtCase) -> some View {
        Section("사건 내용") {
            InfoRow(icon: "📄", text: c.desc.isEmpty ? "(적은 내용이 없어요)" : c.desc)
            if !c.lawIds.isEmpty {
                InfoRow(icon: "📜", text: "어긴 법: \(store.lawLabels(c.lawIds))")
            }
            if !c.want.isEmpty {
                InfoRow(icon: "🎯", text: "\(store.vocab.wantShort(c.type)): \(c.want)")
            }
        }
    }

    // MARK: - 판결

    private func verdictSection(_ c: CourtCase, _ v: Verdict) -> some View {
        Section("판결") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("판결일 \(v.decidedAt) · \(store.vocab.judge) \(store.memName(v.judge))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VerdictBadge(courtCase: c)
                }
                Text("📜 \(v.text)")
                    .font(.system(size: 15))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(10)
            }
            .padding(.vertical, 4)

            if !v.penalty.isEmpty {
                Toggle(isOn: Binding(
                    get: { v.penaltyDone },
                    set: { done in store.update(caseId) { $0.verdict?.penaltyDone = done } }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(store.vocab.penaltyShort(c.type)): \(v.penalty)")
                            .font(.system(size: 14))
                            .strikethrough(v.penaltyDone)
                            .foregroundColor(v.penaltyDone ? .secondary : .primary)
                        if v.penaltyDone {
                            Text("다 지켰어요! 🎉")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .tint(.green)
            }
        }
    }

    // MARK: - 행동

    private func actionSection(_ c: CourtCase) -> some View {
        Section {
            if c.status != .decided {
                Button {
                    showTrial = true
                } label: {
                    Label(c.status == .inTrial ? store.vocab.trialButtonResume : store.vocab.trialButtonOpen,
                          systemImage: "hammer.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Text("이 사건 삭제하기")
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - 작은 부품들

struct RoleRow: View {
    let role: String
    let name: String

    var body: some View {
        HStack {
            Text(role)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 96, alignment: .leading)
            Text(name)
                .font(.system(size: 16, weight: .semibold))
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(icon)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

struct TypeBadge: View {
    @EnvironmentObject var store: Store
    let type: CaseType

    var body: some View {
        Text("\(type.badgeEmoji) \(store.vocab.typeName(type))")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(type == .criminal ? .red : .blue)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background((type == .criminal ? Color.red : Color.blue).opacity(0.14))
            .clipShape(Capsule())
    }
}

struct VerdictBadge: View {
    @EnvironmentObject var store: Store
    let courtCase: CourtCase

    var body: some View {
        let result = courtCase.verdict?.result ?? ""
        let color: Color = {
            switch result {
            case "유죄": return .red
            case "무죄", "피고 승소": return .green
            case "원고 승소": return .blue
            default: return .orange
            }
        }()
        Text(store.vocab.verdictBadge(result))
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }
}

/// 접수 → 재판 → 판결 → 약속 진행 트랙
struct StepTrack: View {
    let current: Int   // 0...4 (4면 모두 완료)

    private let steps: [(emoji: String, label: String)] = [
        ("📮", "접수"), ("🔨", "재판"), ("📜", "판결"), ("🤝", "약속")
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<4, id: \.self) { i in
                if i > 0 {
                    Rectangle()
                        .fill(lineColor(i))
                        .frame(height: 2.5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 13)
                        .padding(.horizontal, -2)
                }
                dot(i)
            }
        }
    }

    private func dot(_ i: Int) -> some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(dotColor(i))
                    .frame(width: 28, height: 28)
                if i < current {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text(steps[i].emoji).font(.system(size: 13))
                }
            }
            Text(steps[i].label)
                .font(.system(size: 11, weight: i == current ? .bold : .medium))
                .foregroundColor(labelColor(i))
        }
    }

    private func dotColor(_ i: Int) -> Color {
        if i < current { return .green }
        if i == current { return .blue }
        return Color(.systemFill)
    }

    private func lineColor(_ i: Int) -> Color {
        if i < current { return .green }
        if i == current { return .blue }
        return Color(.systemFill)
    }

    private func labelColor(_ i: Int) -> Color {
        if i < current { return .green }
        if i == current { return .blue }
        return .secondary
    }
}
