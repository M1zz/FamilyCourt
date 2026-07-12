import Foundation

// MARK: - 어휘 난이도

enum VocabLevel: String, Codable, CaseIterable, Identifiable {
    case easy       // 정말 쉬운 말 (유치원~저학년)
    case standard   // 기본 (초등학생)
    case formal     // 실제 법정 용어

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "쉬운 말"
        case .standard: return "기본"
        case .formal: return "법정 용어"
        }
    }

    var caption: String {
        switch self {
        case .easy: return "어린아이도 알 수 있는 쉬운 말로 보여줘요.\n예) 판사 → 심판, 원고 → 억울한 사람, 판결 → 결정"
        case .standard: return "기본 법원 용어에 쉬운 설명을 곁들여요.\n예) 원고 승소 (원고 말이 맞아요)"
        case .formal: return "실제 법원에서 쓰는 용어 그대로 보여줘요.\n예) 재판장, 최후 진술, 구형, 공소사실 낭독"
        }
    }
}

extension VocabLevel {
    // 모르는 값이 들어와도 안전하게 기본으로
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = VocabLevel(rawValue: raw) ?? .standard
    }
}

// MARK: - 용어 사전 (난이도별 단어를 한곳에서 관리해요)

struct Vocab {
    let level: VocabLevel

    private func pick(_ easy: String, _ standard: String, _ formal: String) -> String {
        switch level {
        case .easy: return easy
        case .standard: return standard
        case .formal: return formal
        }
    }

    // 받침에 따라 조사를 골라 붙여요 (심판이 / 판사가)
    private func particle(_ word: String, _ open: String, _ closed: String) -> String {
        guard let scalar = word.unicodeScalars.last?.value,
              scalar >= 0xAC00, scalar <= 0xD7A3 else { return open }
        return (scalar - 0xAC00) % 28 == 0 ? open : closed
    }
    func ga(_ w: String) -> String { w + particle(w, "가", "이") }      // 이/가
    func neun(_ w: String) -> String { w + particle(w, "는", "은") }    // 은/는
    func eul(_ w: String) -> String { w + particle(w, "를", "을") }     // 을/를
    func wa(_ w: String) -> String { w + particle(w, "와", "과") }      // 와/과

    // MARK: 역할 이름

    var judge: String { pick("심판", "판사", "재판장") }
    var lawyer: String { pick("도와주는 사람", "변호인", "변호인") }
    var clerk: String { pick("적어 주는 사람", "서기", "법원 서기") }

    func accuser(_ t: CaseType) -> String {
        t == .civil
        ? pick("억울한 사람", "원고", "원고")
        : pick("신고한 사람", "검사", "검사")
    }
    func accused(_ t: CaseType) -> String {
        t == .civil
        ? pick("대답하는 사람", "피고", "피고")
        : pick("대답하는 사람", "피고인", "피고인")
    }
    func typeName(_ t: CaseType) -> String {
        t == .civil
        ? pick("억울해요", "민사", "민사")
        : pick("약속 어김", "형사", "형사")
    }

    // MARK: 홈 액션 타일

    var civilTileTitle: String { pick("억울해요!", "억울함 호소하기", "민사 소송 제기") }
    var civilTileSub: String {
        pick("내가 직접 재판을\n신청해요", "내가 원고가 되어\n직접 고소해요 (민사)", "원고가 되어 고소장을\n접수해요 (민사)")
    }
    var criminalTileTitle: String { pick("약속을 어겼어요!", "법 위반 신고하기", "형사 공소 제기") }
    var criminalTileSub: String {
        pick("약속 어긴 사람을\n재판에 데려가요", "내가 검사가 되어\n재판에 넘겨요 (형사)", "검사가 되어 공소장을\n접수해요 (형사)")
    }
    var summonsTileTitle: String { pick("재판에 모여요", "소환 요청 보기", "소환장 확인") }
    func summonsTileSub(_ n: Int) -> String {
        n == 0 ? "지금은 조용해요 🕊️"
        : pick("기다리는 재판 \(n)개", "재판을 기다리는 사건 \(n)건", "계류 중인 사건 \(n)건")
    }
    var archiveTileTitle: String { pick("지난 재판 보기", "판례 보기", "판례 열람") }
    func archiveTileSub(_ n: Int) -> String {
        n == 0 ? pick("끝난 재판 이야기", "끝난 사건과 판결 기록", "종결 사건 기록")
        : pick("끝난 재판 \(n)개", "끝난 사건 \(n)건의 기록", "종결 사건 \(n)건")
    }
    var lawsTileTitle: String { pick("우리 집 약속", "우리 집 법전", "우리 집 법전") }
    var lawsTileSub: String { pick("우리가 정한 약속 보기", "우리가 함께 정한 법 보기", "우리가 함께 정한 법 보기") }

    // MARK: 소송 접수

    func fileTitle(_ t: CaseType) -> String {
        t == .civil
        ? pick("억울해요 재판 신청", "민사 소송 접수 (고소장)", "민사 소 제기 (고소장)")
        : pick("약속 어김 재판 신청", "형사 소송 접수 (공소장)", "형사 공소 제기 (공소장)")
    }
    func fileHint(_ t: CaseType) -> String {
        t == .civil
        ? pick("억울한 일이 있으면 내가 직접 재판을 신청해요. 누구 때문에 억울한지, 누가 심판을 볼지 내가 정해요!",
               "억울한 일이 있는 사람이 직접 접수해요. 누구를 고소할지, 판사는 누구인지 접수하는 사람이 정해요. 접수하면 바로 소송이 시작됩니다!",
               "고소인이 직접 소를 제기합니다. 피고와 재판장은 소를 제기하는 사람이 지정하며, 접수 즉시 소송이 개시됩니다.")
        : pick("약속을 안 지킨 사람을 봤으면 재판을 신청해요. 엄마 아빠도 신청할 수 있어요! 누가 그랬는지, 누가 심판을 볼지 내가 정해요.",
               "우리 집 법을 어긴 사람을 본 사람이 검사가 되어 접수해요. 부모님도 검사가 될 수 있어요! 누구를 재판에 넘길지, 판사는 누구인지 검사가 정해요.",
               "법 위반을 목격한 사람이 검사가 되어 공소를 제기합니다. 피고인과 재판장은 검사가 지정합니다.")
    }
    func accuserFieldLabel(_ t: CaseType) -> String {
        t == .civil
        ? pick("🙋 억울한 사람 (= 나)", "🙋 원고 (고소하는 사람 = 나)", "🙋 원고 (고소인 = 나)")
        : pick("🕵️ 신고한 사람 (= 나)", "🕵️ 검사 (기소하는 사람 = 나)", "🕵️ 검사 (공소 제기 = 나)")
    }
    func accusedFieldLabel(_ t: CaseType) -> String {
        t == .civil
        ? pick("🙇 대답하는 사람 (억울하게 한 사람)", "🙇 피고 (고소당하는 사람)", "🙇 피고")
        : pick("🙇 대답하는 사람 (약속 어긴 사람)", "🙇 피고인 (법을 어긴 사람)", "🙇 피고인")
    }
    var judgeFieldLabel: String { "👨‍⚖️ \(judge)" }
    var judgeFieldFooter: String {
        pick("심판도 신청하는 사람이 직접 골라요. 싸움과 상관없는 사람이 좋아요!",
             "판사도 접수하는 사람이 직접 골라요. 사건과 관련 없는 사람이 좋아요!",
             "재판장은 소를 제기하는 사람이 지정합니다. 사건과 이해관계가 없는 사람이어야 공정합니다.")
    }
    func wantLabel(_ t: CaseType) -> String {
        t == .civil
        ? pick("🎯 바라는 것", "🎯 원하는 것", "🎯 청구 취지 (원하는 것)")
        : pick("🎯 바라는 벌칙", "🎯 구형 (검사가 바라는 벌칙)", "🎯 구형")
    }
    func wantShort(_ t: CaseType) -> String {
        t == .civil ? pick("바라는 것", "원하는 것", "청구 취지") : pick("바라는 벌칙", "구형", "구형")
    }
    func penaltyLabel(_ t: CaseType) -> String {
        t == .civil
        ? pick("🤙 지킬 약속", "🤙 약속 · 보상 (지켜야 할 일)", "🤙 이행 사항 (약속·보상)")
        : pick("⚡ 벌칙", "⚡ 벌칙 (지켜야 할 일)", "⚡ 처분 (벌칙)")
    }
    func penaltyShort(_ t: CaseType) -> String {
        t == .civil ? "🤙 약속" : "⚡ 벌칙"
    }

    // MARK: 상태 · 판결

    func statusText(_ c: CourtCase) -> String {
        switch c.status {
        case .waiting: return pick("재판 기다려요", "재판 대기", "공판 대기")
        case .inTrial: return pick("재판 중이에요", "재판중", "공판 진행중")
        case .decided:
            if let v = c.verdict, !v.penalty.isEmpty, !v.penaltyDone {
                return pick("약속 지키는 중", "약속 남음", "이행 대기")
            }
            return pick("끝났어요", "끝남 ✔", "종결 ✔")
        }
    }

    /// 저장은 항상 표준 값("원고 승소" 등)으로 하고, 보여줄 때만 난이도에 맞춰요.
    func verdictOptions(_ t: CaseType) -> [VerdictOption] {
        if t == .civil {
            return [
                VerdictOption(value: "원고 승소",
                              label: pick("억울한 사람 말이 맞아요", "원고 승소 (원고 말이 맞아요)", "원고 승소")),
                VerdictOption(value: "피고 승소",
                              label: pick("대답한 사람 말이 맞아요", "피고 승소 (피고 말이 맞아요)", "피고 승소")),
                VerdictOption(value: "화해 권고",
                              label: pick("둘이 사이좋게 지내요", "화해 (둘 다 조금씩 양보해요)", "화해 권고"))
            ]
        }
        return [
            VerdictOption(value: "유죄", label: pick("잘못한 게 맞아요", "유죄 (법을 어긴 게 맞아요)", "유죄")),
            VerdictOption(value: "무죄", label: pick("잘못이 없어요", "무죄 (법을 어기지 않았어요)", "무죄")),
            VerdictOption(value: "선처", label: pick("반성해서 용서해요", "선처 (반성해서 용서해요)", "선처"))
        ]
    }

    func verdictBadge(_ canonical: String) -> String {
        switch canonical {
        case "원고 승소": return pick("🙋 억울한 사람 승", "🙋 원고 승소", "🙋 원고 승소")
        case "피고 승소": return pick("🙇 대답한 사람 승", "🙇 피고 승소", "🙇 피고 승소")
        case "화해 권고": return pick("🤝 사이좋게", "🤝 화해", "🤝 화해 권고")
        case "유죄": return pick("⚡ 잘못했어요", "⚡ 유죄", "⚡ 유죄")
        case "무죄": return pick("🕊️ 잘못 없어요", "🕊️ 무죄", "🕊️ 무죄")
        default: return pick("🤗 용서했어요", "🤗 선처", "🤗 선처")
        }
    }

    // MARK: 재판 단계 이름

    var openingTitle: String { pick("재판 시작!", "개정 선언", "개정 선언") }
    var caseIntroTitle: String { pick("무슨 일인지 듣기", "사건 소개", "사건 요지 진술") }
    var indictmentTitle: String { pick("잘못한 일 읽기", "공소사실 읽기 (기소)", "공소사실 낭독") }
    var questioningTitle: String { pick("궁금한 것 묻기", "검사의 질문", "피고인 신문") }
    var defenseTitle: String { pick("도와주기 시간", "변호 시간", "변호인 변론") }
    var demandTitle: String { pick("바라는 벌칙 말하기", "검사의 구형", "구형") }
    var lastWordTitle: String { pick("마지막 한마디", "마지막 한마디 (최후 진술)", "최후 진술") }
    var verdictPrepTitle: String { pick("결정 준비", "판결 준비", "판결 준비") }
    var verdictFormTitle: String { pick("📜 결정하기", "📜 판결 선고", "📜 판결 선고") }
    var verdictTextLabel: String {
        pick("결정한 이유 (심판이 하는 말)", "판결문 (판사가 하는 말)", "판결문 (주문과 이유)")
    }
    var verdictResultLabel: String { pick("어떻게 할까요?", "판결 결과", "주문 (판결 결과)") }
    var trialButtonOpen: String { pick("재판 열기", "재판 열기", "공판 개시") }
    var trialButtonResume: String { pick("재판 이어가기", "재판 이어가기", "공판 속행") }
}

// MARK: - 사건 종류 (민사 / 형사) — 저장용 표준 값

enum CaseType: String, Codable, CaseIterable, Identifiable {
    case civil      // 민사: 억울한 사람(원고)이 직접 고소해요
    case criminal   // 형사: 법을 어긴 걸 본 사람(검사)이 기소해요

    var id: String { rawValue }

    var korean: String { self == .civil ? "민사" : "형사" }     // 사건번호에 쓰는 표준 이름
    var badgeEmoji: String { self == .civil ? "⚖️" : "🚨" }
    var accuserEmoji: String { self == .civil ? "🙋" : "🕵️" }
    var accusedEmoji: String { "🙇" }
    var wantPrompt: String {
        self == .civil ? "예: 사과받고 싶어요 / 과자 물어내기" : "예: 일주일 게임 금지 / 설거지 3번 돕기"
    }
}

struct VerdictOption: Identifiable, Hashable {
    let value: String   // 저장되는 표준 값
    let label: String   // 난이도에 맞춰 보여주는 글
    var id: String { value }
}

// MARK: - 진행 상태

enum CaseStatus: String, Codable {
    case waiting = "재판 대기"
    case inTrial = "재판중"
    case decided = "판결완료"
}

extension CaseStatus {
    // 예전 백업의 "접수됨" 같은 값도 안전하게 읽어요
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = CaseStatus(rawValue: raw) ?? (raw == "판결완료" ? .decided : .waiting)
    }
}

// MARK: - 데이터 모델 (웹 버전 백업 JSON과 키 호환)

struct Member: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var emoji: String
}

struct Law: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var text: String
}

struct Roles: Codable, Hashable {
    var judge: String
    var accuser: String
    var accused: String
    var lawyer: String
    var clerk: String
}

extension Roles {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        judge = try c.decodeIfPresent(String.self, forKey: .judge) ?? ""
        accuser = try c.decodeIfPresent(String.self, forKey: .accuser) ?? ""
        accused = try c.decodeIfPresent(String.self, forKey: .accused) ?? ""
        lawyer = try c.decodeIfPresent(String.self, forKey: .lawyer) ?? ""
        clerk = try c.decodeIfPresent(String.self, forKey: .clerk) ?? ""
    }
}

struct Verdict: Codable, Hashable {
    var result: String
    var text: String
    var penalty: String
    var penaltyDone: Bool
    var decidedAt: String
    var judge: String
}

extension Verdict {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        result = try c.decodeIfPresent(String.self, forKey: .result) ?? ""
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        penalty = try c.decodeIfPresent(String.self, forKey: .penalty) ?? ""
        penaltyDone = try c.decodeIfPresent(Bool.self, forKey: .penaltyDone) ?? false
        decidedAt = try c.decodeIfPresent(String.self, forKey: .decidedAt) ?? ""
        judge = try c.decodeIfPresent(String.self, forKey: .judge) ?? ""
    }
}

struct CourtCase: Codable, Identifiable, Hashable {
    var id: String
    var caseNo: String
    var type: CaseType
    var title: String
    var desc: String
    var want: String
    var lawIds: [String]
    var roles: Roles
    var status: CaseStatus
    var createdAt: String
    var verdict: Verdict?
}

extension CourtCase {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        caseNo = try c.decodeIfPresent(String.self, forKey: .caseNo) ?? ""
        type = try c.decodeIfPresent(CaseType.self, forKey: .type) ?? .civil
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        desc = try c.decodeIfPresent(String.self, forKey: .desc) ?? ""
        want = try c.decodeIfPresent(String.self, forKey: .want) ?? ""
        lawIds = try c.decodeIfPresent([String].self, forKey: .lawIds) ?? []
        roles = try c.decodeIfPresent(Roles.self, forKey: .roles)
            ?? Roles(judge: "", accuser: "", accused: "", lawyer: "", clerk: "")
        status = try c.decodeIfPresent(CaseStatus.self, forKey: .status) ?? .waiting
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        verdict = try c.decodeIfPresent(Verdict.self, forKey: .verdict)
    }
}

// MARK: - 전체 앱 상태

struct AppState: Codable {
    var courtName: String = "우리 집 가정법원"
    var members: [Member] = []
    var laws: [Law] = []
    var cases: [CourtCase] = []
    var seq: Int = 0
    var caseSeq: Int = 0
    var vocabLevel: VocabLevel = .standard

    static let defaultLaws: [Law] = [
        Law(id: "l1", title: "존중", text: "가족은 서로에게 나쁜 말이나 상처 주는 말을 하지 않는다."),
        Law(id: "l2", title: "내 물건과 남의 물건", text: "다른 사람의 물건은 주인에게 허락을 받고 사용한다."),
        Law(id: "l3", title: "정리정돈", text: "자기가 어지른 것은 자기가 정리한다."),
        Law(id: "l4", title: "약속", text: "한 번 한 약속은 지킨다. 지키기 어려울 때는 미리 말한다."),
        Law(id: "l5", title: "화해", text: "재판이 끝나면 결과와 상관없이 서로 안아주고 화해한다.")
    ]
}

extension AppState {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        courtName = try c.decodeIfPresent(String.self, forKey: .courtName) ?? "우리 집 가정법원"
        members = try c.decodeIfPresent([Member].self, forKey: .members) ?? []
        laws = try c.decodeIfPresent([Law].self, forKey: .laws) ?? []
        cases = try c.decodeIfPresent([CourtCase].self, forKey: .cases) ?? []
        seq = try c.decodeIfPresent(Int.self, forKey: .seq) ?? 0
        caseSeq = try c.decodeIfPresent(Int.self, forKey: .caseSeq) ?? 0
        vocabLevel = try c.decodeIfPresent(VocabLevel.self, forKey: .vocabLevel) ?? .standard
    }
}

// MARK: - 재판 대본 한 단계

struct TrialStep {
    let title: String
    let role: String
    let script: String
    var timer: Int? = nil
    var gavel: Bool = false
}

// MARK: - 추천 벌칙 (아동발달 관점: 처벌보다 회복)

struct PenaltyCategory: Identifiable {
    let emoji: String
    let title: String
    let hint: String
    let items: [String]
    var id: String { title }

    /// 교육 효과가 큰 순서대로 — 특권 제한은 마지막 수단이에요.
    static let all: [PenaltyCategory] = [
        PenaltyCategory(
            emoji: "🔧", title: "되돌려 놓기",
            hint: "잘못과 연결된 벌칙이 가장 교육적이에요.",
            items: [
                "망가뜨리거나 먹은 것 물어주기",
                "어지른 곳 스스로 정리하기",
                "망가진 것 같이 고치기"
            ]),
        PenaltyCategory(
            emoji: "💌", title: "마음 돌려주기",
            hint: "상대의 마음을 돌보면 공감하는 힘이 자라요.",
            items: [
                "진심을 담은 사과 편지나 그림 선물하기",
                "상대가 좋아하는 놀이 30분 같이 하기",
                "상대의 좋은 점 3가지 말해주기"
            ]),
        PenaltyCategory(
            emoji: "🌱", title: "다시 안 그러기 약속",
            hint: "스스로 세운 계획은 오래 남아요.",
            items: [
                "다음에 화가 나면 어떻게 할지 계획 세워서 가족 앞에서 발표하기",
                "이번 일로 배운 점을 우리 집 새 법으로 제안하기"
            ]),
        PenaltyCategory(
            emoji: "👀", title: "입장 바꿔보기",
            hint: "상대 마음을 상상해 보는 연습이 돼요.",
            items: [
                "상대 입장에서 그날 일을 다시 이야기해보기",
                "다음 재판에서 상대편 도와주는 역할 맡기"
            ]),
        PenaltyCategory(
            emoji: "🧺", title: "가족 돕기",
            hint: "횟수를 정해서 짧고 구체적으로!",
            items: [
                "설거지 3번 돕기",
                "빨래 개기 2번 돕기",
                "3일 동안 신발 정리하기"
            ]),
        PenaltyCategory(
            emoji: "🎮", title: "아껴 쓰기",
            hint: "게임·TV 줄이기는 짧게, 마지막 수단으로만!",
            items: [
                "오늘 게임 시간 절반으로 줄이기",
                "내일 하루 TV 쉬기"
            ])
    ]
}
