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
}
