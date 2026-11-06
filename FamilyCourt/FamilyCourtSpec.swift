import Foundation
import LeeoKit

enum FamilyCourtSpec: LeeoAppSpec {
    static let appName = "억울해요"
    static let developerEmail = "leeo@kakao.com"
    static let feedback = LeeoFeedbackConfig(containerIdentifier: "iCloud.com.Ysoup.FeedbackHub", appIdentifier: "com.family.familycourt")

    /// 정책 링크 — README 의 개인정보 처리방침 · 지원 페이지와 같은 주소.
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/FamilyCourt/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/FamilyCourt/support.html")!,
        marketingURL: URL(string: "https://m1zz.github.io/FamilyCourt/")!
    )

    /// 무료 · Pro 두 칸. 재판은 언제나 무료, 큰 가족과 긴 법전 · Siri · 법원 이름이 Pro 다 (→ Pro.swift).
    /// Pro 는 주 · 월 · 연 구독(한 구독 그룹)과 평생, 구독자에게만 보이는 구독 졸업 평생.
    static let monetization = LeeoMonetization.freemiumSubscription(
        LeeoSubscriptionConfig(
            productIDs: Pro.productIDs,
            // 자체 약관이 없으므로 애플 표준 사용권 계약(EULA)을 건다. 구독을 파는 앱의 심사 필수 항목이다.
            termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
            gate: Pro.gatePolicy,
            // 개발자 응원(팁). 소모성 세 가지, 작은 것부터. 기능을 열지 않는다.
            // ⚠️ 권한 상품(productIDs)에 넣지 않는다. 넣으면 팁을 낸 사람이 Pro 가 된다.
            tipJar: LeeoTipJarConfig(productIDs: Pro.tipProductIDs)))

    /// App Store 앱 ID — 리뷰 링크 · 친구에게 소개하기에 쓴다.
    static var appStoreID: String? { "6790131247" }

    /// 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: FamilyCourtSpec.self)
}
