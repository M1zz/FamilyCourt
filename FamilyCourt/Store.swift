import Foundation
import SwiftUI

@MainActor
final class Store: ObservableObject {

    @Published var data: AppState {
        didSet { persist() }
    }

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("familycourt.json")
    }()

    init() {
        if let raw = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(AppState.self, from: raw) {
            data = saved
        } else {
            var fresh = AppState()
            fresh.laws = AppState.defaultLaws
            data = fresh
        }
    }

    private func persist() {
        guard let raw = try? JSONEncoder().encode(data) else { return }
        try? raw.write(to: fileURL, options: .atomic)
    }

    /// 설정된 어휘 난이도에 맞는 용어 사전
    var vocab: Vocab { Vocab(level: data.vocabLevel) }

    // MARK: - 조회 도우미

    func member(_ id: String) -> Member? {
        data.members.first { $0.id == id }
    }

    func memName(_ id: String) -> String {
        guard let m = member(id) else { return String(localized: "❓ 미정", comment: "Role not assigned yet") }
        return "\(m.emoji) \(m.name)"
    }

    func lawLabel(_ id: String) -> String? {
        guard let i = data.laws.firstIndex(where: { $0.id == id }) else { return nil }
        return String(localized: "제\(i + 1)조 \(data.laws[i].title)", comment: "House law label: article number, title")
    }

    func lawLabels(_ ids: [String]) -> String {
        ids.compactMap { lawLabel($0) }.joined(separator: ", ")
    }

    func courtCase(_ id: String) -> CourtCase? {
        data.cases.first { $0.id == id }
    }

    var openCases: [CourtCase] { data.cases.filter { $0.status != .decided } }
    var doneCases: [CourtCase] { data.cases.filter { $0.status == .decided } }

    func todayString() -> String {
        let c = Calendar.current
        let now = Date()
        // 한국어는 예전 기록과 같은 꼴(2026. 10. 5.), 다른 언어는 그 지역 날짜 꼴(05/10/2026 등)
        guard Vocab.usesKoreanParticles else { return now.formatted(date: .numeric, time: .omitted) }
        return "\(c.component(.year, from: now)). \(c.component(.month, from: now)). \(c.component(.day, from: now))."
    }

    // MARK: - 가족

    func addMember(name: String, emoji: String) {
        data.members.append(Member(id: UUID().uuidString, name: name, emoji: emoji))
    }

    func deleteMember(_ id: String) {
        data.members.removeAll { $0.id == id }
    }

    // MARK: - 법전

    func addLaw(title: String, text: String) {
        data.laws.append(Law(id: UUID().uuidString, title: title, text: text))
    }

    func updateLaw(_ id: String, title: String, text: String) {
        guard let i = data.laws.firstIndex(where: { $0.id == id }) else { return }
        data.laws[i].title = title
        data.laws[i].text = text
    }

    func deleteLaw(_ id: String) {
        data.laws.removeAll { $0.id == id }
    }

    // MARK: - 소송

    /// 접수하는 사람(원고·검사)이 상대와 판사를 직접 정하면 그 순간 소송이 시작돼요.
    func fileCase(type: CaseType, title: String, desc: String, want: String,
                  lawIds: [String], judge: String, accuser: String, accused: String) -> String {
        data.caseSeq += 1
        let year = Calendar.current.component(.year, from: Date())
        let newCase = CourtCase(
            id: UUID().uuidString,
            caseNo: type.caseNumber(year: year, seq: data.caseSeq),
            type: type, title: title, desc: desc, want: want, lawIds: lawIds,
            roles: Roles(judge: judge, accuser: accuser, accused: accused, lawyer: "", clerk: ""),
            status: .waiting, createdAt: todayString(), verdict: nil
        )
        data.cases.insert(newCase, at: 0)
        return newCase.id
    }

    func update(_ id: String, _ mutate: (inout CourtCase) -> Void) {
        guard let i = data.cases.firstIndex(where: { $0.id == id }) else { return }
        mutate(&data.cases[i])
    }

    func deleteCase(_ id: String) {
        data.cases.removeAll { $0.id == id }
    }

    // MARK: - 백업

    func writeBackupFile() -> URL? {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let raw = try? enc.encode(data) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(String(localized: "가정법원기록", comment: "Backup file name (no extension)") + ".json")
        do {
            try raw.write(to: url, options: .atomic)
            return url
        } catch { return nil }
    }

    func importBackup(from url: URL) throws {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }
        let raw = try Data(contentsOf: url)
        data = try JSONDecoder().decode(AppState.self, from: raw)
    }

    // MARK: - 재판 대본 (어휘 난이도를 따라가요)

    func trialSteps(for c: CourtCase) -> [TrialStep] {
        let t = c.type
        let r = c.roles
        let v = vocab
        let laws = lawLabels(c.lawIds).isEmpty ? String(localized: "(고른 법 없음)") : lawLabels(c.lawIds)

        let judgeWord = v.judge
        let accuserWord = v.accuser(t)
        let accusedWord = v.accused(t)
        let judgeTag = "👨‍⚖️ \(judgeWord) · \(memName(r.judge))"
        let accuserTag = "\(t.accuserEmoji) \(accuserWord) · \(memName(r.accuser))"
        let accusedTag = "\(t.accusedEmoji) \(accusedWord) · \(memName(r.accused))"
        let defenseTag = r.lawyer.isEmpty
            ? "🛡️ \(accusedWord) · \(memName(r.accused))"
            : "🛡️ \(v.lawyer) · \(memName(r.lawyer))"
        let defenseIntro = r.lawyer.isEmpty
            ? String(localized: "\(v.ga(v.lawyer)) 없으니 \(v.ga(accusedWord)) 스스로 자기편 이야기를 해요")
            : String(localized: "\(v.ga(v.lawyer)) \(v.eul(accusedWord)) 도와서 말해요")
        let descText = c.desc.isEmpty ? String(localized: "(내용 없음)") : c.desc
        let wantText = c.want.isEmpty ? String(localized: "(바라는 벌칙을 말해 주세요)") : c.want
        let wantQuote = c.want.isEmpty ? "" : String(localized: "(“\(c.want)”)", comment: "Quoted wish of the plaintiff")

        if t == .criminal {
            return [
                TrialStep(title: v.openingTitle, role: judgeTag,
                          script: String(localized: "\(v.ga(judgeWord)) 큰 소리로 말해요:\n\n\"지금부터 \(data.courtName) \(v.typeName(t)) 재판을 시작하겠습니다.\n사건번호 \(c.caseNo), 「\(c.title)」 사건입니다.\n모두 바르게 앉아 주세요!\""),
                          gavel: true),
                TrialStep(title: v.indictmentTitle, role: accuserTag,
                          script: String(localized: "\(v.ga(accuserWord)) \(v.ga(accusedWord)) 무엇을 잘못했는지 읽어요:\n\n\"\(accusedWord) \(v.neun(memName(r.accused))) 다음과 같이 우리 집 법을 어겼습니다.\"\n\n📄 사건 내용: \(descText)\n📜 어긴 법: \(laws)")),
                TrialStep(title: String(localized: "\(accusedWord)의 이야기"), role: accusedTag,
                          script: String(localized: "\(v.ga(accusedWord)) 이야기해요:\n\n• 정말 그런 일이 있었나요? 맞나요, 아닌가요?\n• 왜 그렇게 했나요? 내 생각을 이야기해요.\n\n⭐ 규칙: 솔직하게 말하기, 소리 지르지 않기!"),
                          timer: 120),
                TrialStep(title: v.questioningTitle, role: accuserTag,
                          script: String(localized: "\(v.ga(accuserWord)) \(v.eul(accusedWord))에게 궁금한 것을 질문해요:\n\n\"○○한 것이 사실입니까?\"\n\"왜 그렇게 했습니까?\"\n\n\(v.neun(accusedWord)) 솔직하게 대답해요."),
                          timer: 90),
                TrialStep(title: v.defenseTitle, role: defenseTag,
                          script: String(localized: "\(defenseIntro):\n\n\"\(accusedWord)에게도 이런 사정이 있었습니다...\"\n\"\(v.neun(accusedWord)) 이렇게 반성하고 있습니다...\"\n\n\(v.eul(accusedWord)) 지켜 주는 좋은 이유를 찾아보세요!"),
                          timer: 90),
                TrialStep(title: v.demandTitle, role: accuserTag,
                          script: String(localized: "\(v.ga(accuserWord)) 어떤 벌칙이 좋을지 말해요:\n\n\"\(accusedWord)에게 다음 벌칙을 내려 주시기 바랍니다.\n\(wantText)\"\n\n⭐ 벌칙은 너무 무겁지 않게, 지킬 수 있는 것으로!")),
                TrialStep(title: String(localized: "\(accusedWord)의 \(v.lastWordTitle)"), role: accusedTag,
                          script: String(localized: "\(v.ga(accusedWord)) 마지막으로 하고 싶은 말을 해요:\n\n\"저는 ○○해서 죄송합니다.\"\n\"앞으로는 ○○하겠습니다.\"\n\n진심을 담아서 이야기해요."),
                          timer: 60),
                TrialStep(title: v.verdictPrepTitle, role: judgeTag,
                          script: String(localized: "\(v.neun(judgeWord)) 눈을 감고 10초 동안 곰곰이 생각해요. 🤔\n\n• 정말 법을 어겼을까?\n• 반성하고 있을까?\n• 어떤 벌칙이면 다시 안 그럴까? 아니면 용서해 줄까?\n\n준비가 되면 [다음]을 눌러요!"),
                          gavel: true)
            ]
        }

        return [
            TrialStep(title: v.openingTitle, role: judgeTag,
                      script: String(localized: "\(v.ga(judgeWord)) 큰 소리로 말해요:\n\n\"지금부터 \(data.courtName) \(v.typeName(t)) 재판을 시작하겠습니다.\n사건번호 \(c.caseNo), 「\(c.title)」 사건입니다.\n모두 바르게 앉아 주세요!\""),
                      gavel: true),
            TrialStep(title: v.caseIntroTitle,
                      role: r.clerk.isEmpty ? judgeTag : "✍️ \(v.clerk) · \(memName(r.clerk))",
                      script: String(localized: "\(v.ga(r.clerk.isEmpty ? judgeWord : v.clerk)) 사건을 읽어 줘요:\n\n\"이 사건은 \(accuserWord) \(memName(r.accuser)) 님이 \(accusedWord) \(memName(r.accused)) 님과 있었던 일을 재판해 달라고 낸 사건입니다.\"\n\n📄 사건 내용: \(descText)\n📜 어긴 법: \(laws)")),
            TrialStep(title: String(localized: "\(accuserWord)의 이야기"), role: accuserTag,
                      script: String(localized: "\(v.ga(accuserWord)) 이야기해요:\n\n• 언제, 어디서, 무슨 일이 있었나요?\n• 어떤 기분이 들었나요?\n• 무엇을 바라나요? \(wantQuote)\n\n⭐ 규칙: 소리 지르지 않기, 사실만 말하기!"),
                      timer: 120),
            TrialStep(title: String(localized: "\(accusedWord)의 이야기"), role: accusedTag,
                      script: String(localized: "이번엔 \(accusedWord) 차례예요:\n\n• 정말 그런 일이 있었나요?\n• 왜 그렇게 했나요? 내 생각을 이야기해요.\n\n⭐ 규칙: 끝까지 듣고, 끼어들지 않기!"),
                      timer: 120),
            TrialStep(title: String(localized: "서로 묻고 답하기"), role: "\(accuserTag) ↔ \(accusedTag)",
                      script: String(localized: "\(v.wa(accuserWord)) \(v.ga(accusedWord)) 서로 궁금한 것을 물어봐요:\n\n\"그때 왜 그랬어?\"\n\"내가 어떻게 해 줬으면 좋겠어?\"\n\n⭐ 규칙: 한 사람씩 차례대로, 화내지 않고!"),
                      timer: 90),
            TrialStep(title: v.defenseTitle, role: defenseTag,
                      script: String(localized: "\(defenseIntro):\n\n\"\(accusedWord)에게도 이런 사정이 있었습니다...\"\n\"\(v.neun(accusedWord)) 이렇게 반성하고 있습니다...\"\n\n\(v.eul(accusedWord)) 지켜 주는 좋은 이유를 찾아보세요!"),
                      timer: 90),
            TrialStep(title: v.lastWordTitle, role: "\(accuserTag) → \(accusedTag)",
                      script: String(localized: "\(v.wa(accuserWord)) \(v.ga(accusedWord)) 한 사람씩 마지막으로 하고 싶은 말을 해요.\n\n\(accuserWord): \"저는 ○○을 바랍니다.\"\n\(accusedWord): \"저는 ○○하겠습니다.\"\n\n한 사람당 30초씩!"),
                      timer: 60),
            TrialStep(title: v.verdictPrepTitle, role: judgeTag,
                      script: String(localized: "\(v.neun(judgeWord)) 눈을 감고 10초 동안 곰곰이 생각해요. 🤔\n\n• 누구 말이 맞을까?\n• 우리 집 법으로 보면 어떨까?\n• 어떤 약속을 하면 다시 사이좋게 지낼 수 있을까?\n\n준비가 되면 [다음]을 눌러요!"),
                      gavel: true)
        ]
    }
}
