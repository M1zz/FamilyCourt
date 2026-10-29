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

    /// 기능을 여는 인앱 결제 없음.
    static let monetization = LeeoMonetization.free

    /// 개발자 응원(팁). 소모성 세 가지, 작은 것부터. 기능을 열지 않는다 — 무료 앱이라 혼자 돈다(`startStandalone`).
    @MainActor static let tipJar = LeeoTipJar(config: LeeoTipJarConfig(productIDs: [
        "com.family.familycourt.tip.small", "com.family.familycourt.tip.medium", "com.family.familycourt.tip.large",
    ]))

    /// App Store 앱 ID — 리뷰 링크 · 친구에게 소개하기에 쓴다.
    static var appStoreID: String? { "6790131247" }

    /// 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: FamilyCourtSpec.self)
}
