import Foundation
import LeeoKit

/// 원격 킬스위치 — LeeoKit(LeeoRemoteFlags)이 CloudKit `RemoteFlags` 레코드에서 읽는다.
///
/// ⚠️ rawValue = CloudKit 필드명 계약이다. 바꾸면 아무리 꺼도 켜진 채로 돈다. 변경 금지.
/// ⚠️ 조회 실패 = 켬(가용성 우선). 갱신은 6시간 쓰로틀이라 다음 실행부터 반영된다.
///
/// CloudKit Dashboard (iCloud.com.Ysoup.FeedbackHub, 1회): 레코드 타입 RemoteFlags,
/// recordName `flags_com.family.familycourt`, 각 플래그를 Int64(1=켬, 0=끔) 필드로 만들고
/// Production 배포. 필드가 없으면 켬으로 동작한다.
enum FamilyCourtFlag: String, LeeoRemoteFlag, CaseIterable {
    /// 의사봉·타이머 종료음 합성(AVAudioEngine). 특정 기기에서 오디오가 말썽이면 끈다 —
    /// 꺼도 진동(햅틱)은 그대로 나서 재판 진행에는 지장이 없다.
    case synthSoundEnabled
    /// "즐겁게 쓰고 계신가요?" 만족도 질문. 재판 도중에 끼어든다는 신고가 오면 끈다.
    case satisfactionPromptEnabled
    /// MetricKit 크래시·행 진단 업로드(LeeoDiagnostics). 끄면 다음 실행부터 보내지 않는다.
    case diagnosticsEnabled
}
