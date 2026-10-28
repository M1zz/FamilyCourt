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

    /// 인앱 결제 없음.
    static let monetization = LeeoMonetization.free

    /// App Store 앱 ID — 리뷰 링크 · 친구에게 소개하기에 쓴다.
    static var appStoreID: String? { "6790131247" }

    /// 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: FamilyCourtSpec.self)
}
