//
//  FamilyCourtRoadmap.swift
//  FamilyCourt
//
//  **앞으로 만들 것**의 원본. 설정 ▸ 앞으로 만들 기능(`LeeoRoadmapView`)이 이 목록을 그대로 보여 준다.
//
//  ⚠️ 개발하다 "이건 다음에" 가 생기면 **여기에 한 줄을 더한다.** 코드의 TODO 주석으로만 남기지 않는다.
//     - 새 항목: `.planned`. 손대기 시작하면 `.building`. 내보내면 `.shipped("1.2.0")`.
//     - id 는 한 번 정하면 바꾸지 않는다(문구는 바꿔도 된다). 다른 앱과 같은 피처는 같은 id 를 쓴다.
//     - 문구는 사용자 말로 쓴다(내부 이름 · 기술 용어 금지). 영어는 FamilyCourt/Localizable.xcstrings 에 넣는다
//       (한국어 전용 앱이라 카탈로그에는 이 화면 문구만 있다 — 영어가 빠지면 영어 쓰는 사람에게 한국어가 보인다).
//     - 사용자에게 보일 만한 것만 적는다. 리팩터링 · 시험 · 빌드 설정은 `.sprintcommander/tasks.json` 의 몫이다.
//

import SwiftUI
import LeeoKit

extension FamilyCourtSpec {
    static var roadmap: [LeeoRoadmapItem] {[
        // MARK: 다음에 만들어요
        .init(id: "a11y.voiceover", status: .planned,
              title: NSLocalizedString("VoiceOver로 더 편하게", comment: "Roadmap item: VoiceOver"),
              detail: NSLocalizedString("화면 읽기 기능이 단추와 내용을 빠짐없이, 알맞은 순서로 읽어 줘요.", comment: "Roadmap item detail: VoiceOver")),
        .init(id: "a11y.largetext", status: .planned,
              title: NSLocalizedString("큰 글씨에 맞춘 화면", comment: "Roadmap item: larger text layouts"),
              detail: NSLocalizedString("글자 크기를 키워도 잘리지 않고 보기 좋게 다시 배치돼요.", comment: "Roadmap item detail: larger text layouts")),
        .init(id: "display.dark", status: .planned,
              title: NSLocalizedString("다크 모드", comment: "Roadmap item: dark mode"),
              detail: NSLocalizedString("어두운 화면에서도 글자와 단추가 또렷하게 보여요.", comment: "Roadmap item detail: dark mode")),
        .init(id: "a11y.contrast", status: .planned,
              title: NSLocalizedString("보기 편한 색과 대비", comment: "Roadmap item: colors and contrast"),
              detail: NSLocalizedString("대비를 높이거나 색을 구별하기 어려워도 내용을 알아볼 수 있어요.", comment: "Roadmap item detail: colors and contrast")),
        .init(id: "a11y.motion", status: .planned,
              title: NSLocalizedString("움직임 줄이기", comment: "Roadmap item: reduce motion"),
              detail: NSLocalizedString("움직임 줄이기를 켜면 화면 효과가 차분해져요.", comment: "Roadmap item detail: reduce motion")),
        .init(id: "a11y.keyboard", status: .planned,
              title: NSLocalizedString("키보드로 조작하기", comment: "Roadmap item: keyboard control"),
              detail: NSLocalizedString("아이패드에서 키보드만으로 주요 기능을 쓸 수 있어요.", comment: "Roadmap item detail: keyboard control")),
        .init(id: "lang.english", status: .shipped("1.0.1"),
              title: NSLocalizedString("영어 지원", comment: "Roadmap item: English"),
              detail: NSLocalizedString("앱을 영어로도 쓸 수 있어요.", comment: "Roadmap item detail: English")),
        .init(id: "lang.more", status: .shipped("1.0.1"),
              title: NSLocalizedString("더 많은 언어", comment: "Roadmap item: more languages"),
              detail: NSLocalizedString("더 많은 나라 말로 앱을 쓸 수 있게 해요.", comment: "Roadmap item detail: more languages")),
        .init(id: "whatsnew", status: .planned,
              title: NSLocalizedString("업데이트 소식", comment: "Roadmap item: what's new after an update"),
              detail: NSLocalizedString("업데이트 뒤 처음 열 때 무엇이 새로 생겼는지 알려 줘요.", comment: "Roadmap item detail: what's new after an update")),
        .init(id: "widgets", status: .planned,
              title: NSLocalizedString("홈 화면 위젯", comment: "Roadmap item: home screen widgets"),
              detail: NSLocalizedString("앱을 열지 않고 홈 화면에서 진행 중인 소송을 바로 확인해요.", comment: "Roadmap item detail: home screen widgets")),
        .init(id: "sync.icloud", status: .planned,
              title: NSLocalizedString("기기 간 동기화", comment: "Roadmap item: sync across devices"),
              detail: NSLocalizedString("아이폰과 아이패드에서 같은 기록을 이어서 써요.", comment: "Roadmap item detail: sync across devices")),
        .init(id: "lock.faceid", status: .planned,
              title: NSLocalizedString("Face ID 잠금", comment: "Roadmap item: Face ID lock"),
              detail: NSLocalizedString("Face ID나 Touch ID로 앱을 잠가 우리 집 기록을 지켜요.", comment: "Roadmap item detail: Face ID lock")),
        .init(id: "notifications", status: .planned,
              title: NSLocalizedString("알림", comment: "Roadmap item: notifications"),
              detail: NSLocalizedString("판결에서 정한 일을 잊지 않도록 알맞은 때에 알려 줘요.", comment: "Roadmap item detail: notifications")),
        .init(id: "fold", status: .planned,
              title: NSLocalizedString("펼치는 아이폰 화면", comment: "Roadmap item: foldable iPhone layout"),
              detail: NSLocalizedString("펼치는 아이폰에서 넓은 화면을 두 쪽으로 나눠 써요.", comment: "Roadmap item detail: foldable iPhone layout")),
        .init(id: "data.delete", status: .planned,
              title: NSLocalizedString("내 데이터 한 번에 지우기", comment: "Roadmap item: delete all my data"),
              detail: NSLocalizedString("원하면 앱 안에서 모든 기록을 한 번에 지울 수 있어요.", comment: "Roadmap item detail: delete all my data")),
        .init(id: "autosave", status: .planned,
              title: NSLocalizedString("쓰던 소송 이어서 쓰기", comment: "Roadmap item: keep a half-written filing"),
              detail: NSLocalizedString("소송을 접수하다 앱이 꺼져도 쓰던 내용이 남아 있어요.", comment: "Roadmap item detail: keep a half-written filing")),
    ]}
}

// MARK: - 화면

/// 설정 ▸ 앞으로 만들 기능. "이런 기능이 있으면 좋겠어요" 는 기능 제안으로 시작하는 피드백 창을 연다.
struct RoadmapScreen: View {
    @State private var showFeedback = false

    var body: some View {
        LeeoRoadmapView<FamilyCourtSpec>(onSuggest: { showFeedback = true })
            .sheet(isPresented: $showFeedback) {
                // LeeoFeedbackView 는 자기 NavigationStack 과 닫기 단추를 갖고 있다 — 감싸지 않는다.
                LeeoFeedbackView<FamilyCourtSpec>(initialType: .feature)
            }
    }
}
