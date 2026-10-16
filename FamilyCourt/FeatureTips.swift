import SwiftUI
import TipKit

// 사용 팁 — 눈에 잘 띄지 않는 기능을 그 기능이 있는 화면에서 한 번만 알려 줘요.
// 표시 빈도·닫힘 기록은 TipKit 이 관리한다 (FamilyCourtApp 의 Tips.configure).

/// 법전: 법 한 줄을 밀면 고치기·없애기가 나온다.
struct LawSwipeTip: Tip {
    var title: Text { Text("법을 밀어서 고쳐요") }
    var message: Text? {
        Text("법을 왼쪽으로 밀면 [고치기]와 [없애기]가 나와요. 가족회의에서 모두 동의했을 때 바꿔 주세요.")
    }
    var image: Image? { Image(systemName: "hand.draw") }
}

/// 법원 공부하기: 어휘 난이도에 따라 역할 이름이 바뀐다.
struct VocabLevelTip: Tip {
    var title: Text { Text("아이 나이에 맞는 말로 바꿔요") }
    var message: Text? {
        Text("설정의 [어휘 난이도]를 '쉬운 말'로 고르면 판사는 심판, 원고는 억울한 사람처럼 쉬운 말로 보여요.")
    }
    var image: Image? { Image(systemName: "textformat.size") }
}
