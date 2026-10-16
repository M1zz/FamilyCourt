import XCTest
@testable import FamilyCourt

/// 재판 대본의 문장을 만드는 조사 규칙 — 틀리면 아이가 읽는 대본이 어색해진다.
final class VocabParticleTests: XCTestCase {
    private let v = Vocab(level: .standard)

    func testSubjectParticleFollowsFinalConsonant() {
        XCTAssertEqual(v.ga("판사"), "판사가")       // 받침 없음
        XCTAssertEqual(v.ga("심판"), "심판이")       // 받침 있음
        XCTAssertEqual(v.ga("재판장"), "재판장이")
    }

    func testTopicObjectAndConjunctionParticles() {
        XCTAssertEqual(v.neun("검사"), "검사는")
        XCTAssertEqual(v.neun("피고인"), "피고인은")
        XCTAssertEqual(v.eul("변호인"), "변호인을")
        XCTAssertEqual(v.eul("서기"), "서기를")
        XCTAssertEqual(v.wa("원고"), "원고와")
        XCTAssertEqual(v.wa("억울한 사람"), "억울한 사람과")
    }

    func testNonHangulEndingUsesVowelForm() {
        // 이모지·영문으로 끝나는 이름은 받침을 알 수 없으니 받침 없는 꼴을 쓴다.
        XCTAssertEqual(v.ga("Tom"), "Tom가")
        XCTAssertEqual(v.eul("🐶"), "🐶를")
        XCTAssertEqual(v.ga(""), "가")
    }
}

/// 어휘 난이도에 따라 역할 이름이 바뀌는지.
final class VocabLevelTests: XCTestCase {
    func testRoleNamesPerLevel() {
        XCTAssertEqual(Vocab(level: .easy).judge, "심판")
        XCTAssertEqual(Vocab(level: .standard).judge, "판사")
        XCTAssertEqual(Vocab(level: .formal).judge, "재판장")
        XCTAssertEqual(Vocab(level: .standard).accuser(.civil), "원고")
        XCTAssertEqual(Vocab(level: .standard).accuser(.criminal), "검사")
        XCTAssertEqual(Vocab(level: .easy).accused(.criminal), "대답하는 사람")
    }

    func testVerdictValuesAreStableAcrossLevels() {
        // 판결은 표준 값으로 저장된다 — 난이도가 바뀌어도 저장 값이 달라지면 안 된다.
        for level in VocabLevel.allCases {
            let v = Vocab(level: level)
            XCTAssertEqual(v.verdictOptions(.civil).map(\.value), ["원고 승소", "피고 승소", "화해 권고"])
            XCTAssertEqual(v.verdictOptions(.criminal).map(\.value), ["유죄", "무죄", "선처"])
        }
    }

    func testStatusTextShowsPendingPromise() {
        let v = Vocab(level: .standard)
        var c = CourtCase(id: "c", caseNo: "2026민사1호", type: .civil, title: "", desc: "", want: "",
                          lawIds: [], roles: Roles(judge: "", accuser: "", accused: "", lawyer: "", clerk: ""),
                          status: .decided, createdAt: "",
                          verdict: Verdict(result: "원고 승소", text: "", penalty: "사과하기",
                                           penaltyDone: false, decidedAt: "", judge: ""))
        XCTAssertEqual(v.statusText(c), "약속 남음")
        c.verdict?.penaltyDone = true
        XCTAssertEqual(v.statusText(c), "끝남 ✔")
        c.status = .waiting
        XCTAssertEqual(v.statusText(c), "재판 대기")
    }
}

/// 백업 파일 호환 — 예전 웹 버전·이전 앱 버전의 기록을 그대로 불러올 수 있어야 한다.
final class BackupCompatibilityTests: XCTestCase {
    private func decode(_ json: String) throws -> AppState {
        try JSONDecoder().decode(AppState.self, from: Data(json.utf8))
    }

    func testEmptyObjectFallsBackToDefaults() throws {
        let s = try decode("{}")
        XCTAssertEqual(s.courtName, "우리 집 가정법원")
        XCTAssertTrue(s.members.isEmpty)
        XCTAssertTrue(s.cases.isEmpty)
        XCTAssertEqual(s.vocabLevel, .standard)
    }

    func testLegacyValuesAreReadSafely() throws {
        let s = try decode("""
        {
          "courtName": "김씨네 가정법원",
          "vocabLevel": "kindergarten",
          "members": [{"id": "m1", "name": "아빠", "emoji": "👨"}],
          "cases": [
            {"id": "c1", "title": "과자 사건", "status": "접수됨", "roles": {"judge": "m1"}},
            {"title": "끝난 사건", "type": "criminal", "status": "판결완료",
             "verdict": {"result": "유죄"}}
          ]
        }
        """)
        XCTAssertEqual(s.courtName, "김씨네 가정법원")
        XCTAssertEqual(s.vocabLevel, .standard)              // 모르는 난이도 → 기본
        XCTAssertEqual(s.cases[0].status, .waiting)          // "접수됨" → 재판 대기
        XCTAssertEqual(s.cases[0].roles.judge, "m1")
        XCTAssertEqual(s.cases[0].roles.accuser, "")         // 빠진 역할은 빈 값
        XCTAssertEqual(s.cases[0].type, .civil)              // 종류가 없으면 민사
        XCTAssertFalse(s.cases[1].id.isEmpty)                // id 가 없으면 새로 만든다
        XCTAssertEqual(s.cases[1].status, .decided)
        XCTAssertEqual(s.cases[1].verdict?.result, "유죄")
        XCTAssertEqual(s.cases[1].verdict?.penaltyDone, false)
    }

    func testRoundTripKeepsEverything() throws {
        var s = AppState()
        s.courtName = "우리 집"
        s.laws = AppState.defaultLaws
        s.members = [Member(id: "m1", name: "엄마", emoji: "👩")]
        s.caseSeq = 3
        s.vocabLevel = .formal
        let back = try JSONDecoder().decode(AppState.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(back.courtName, s.courtName)
        XCTAssertEqual(back.laws, s.laws)
        XCTAssertEqual(back.members, s.members)
        XCTAssertEqual(back.caseSeq, 3)
        XCTAssertEqual(back.vocabLevel, .formal)
    }
}
