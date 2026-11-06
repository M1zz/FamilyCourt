//
//  Pro.swift
//  FamilyCourt
//
//  억울해요 Pro — 무료 · Pro 두 칸. **재판은 언제나 무료다.**
//  접수 · 역할 · 대본 · 타이머 · 판결 · 약속 · 어휘 난이도 · 지난 사건 · 백업은 잠그지 않는다.
//  Pro 는 식구가 많고 법이 많은 집, 시리로 바로 법정을 여는 집을 위한 것이다.
//
//  속은 전부 `LeeoStore` 다(상품 로드 · 구매 · 복원 · 가족 공유 · 환불 · 만료). 앱은 `hasPro` 와 게이트만 본다.
//  결제 화면은 늘 어른 확인 뒤에 열린다(`UnlockSheet`) — 이 앱을 주로 쓰는 사람은 아이다.
//

import Foundation
import StoreKit
import LeeoKit

enum Pro {

    // MARK: - 상품 ID
    //
    // ⚠️ App Store Connect · FamilyCourt.storekit 과 글자 하나까지 같아야 한다.
    //    구독 셋은 한 구독 그룹("억울해요 Pro")에 둔다.

    /// Pro 평생 (비소모성, 가족 공유).
    static let lifetimeID = "com.family.familycourt.pro"
    /// Pro 연 구독. 처음 구독하는 사람은 첫 해 반값(App Store 소개 할인).
    static let yearlyID = "com.family.familycourt.pro.yearly"
    /// Pro 월 구독.
    static let monthlyID = "com.family.familycourt.pro.monthly"
    /// Pro 주 구독.
    static let weeklyID = "com.family.familycourt.pro.weekly"
    /// 구독 졸업 Pro 평생 (비소모성). 구독 중인 사람에게만 보인다(→ LeeoGraduation).
    static let graduateID = "com.family.familycourt.pro.graduate"

    /// 개발자 응원 팁. 아무것도 열지 않는다 — 권한 상품에 넣지 않는다.
    static let tipProductIDs = [
        "com.family.familycourt.tip.small", "com.family.familycourt.tip.medium", "com.family.familycourt.tip.large",
    ]

    /// 페이월이 불러올 상품. 순서는 화면 순서와 상관없다(화면은 ID 로 골라 쓴다).
    static let productIDs = [yearlyID, lifetimeID, monthlyID, weeklyID, graduateID]

    /// 자동 갱신 구독 — 구독 졸업을 제안할 대상.
    static let subscriptionIDs: Set<String> = [weeklyID, monthlyID, yearlyID]

    // MARK: - 무료 한도

    /// 가족 등록부. 일곱 번째 식구부터 Pro.
    static let freeMembers = 6
    /// 우리 집 법전. 열세 번째 조문부터 Pro.
    static let freeLaws = 12

    /// 게이트 열쇠말. 문자열을 흩어 적으면 오타 하나로 조용히 안 잠긴다.
    enum Gate {
        static let members = "members"
        static let laws = "laws"
        static let siri = "siri"
        static let courtName = "courtName"
    }

    static let gatePolicy = LeeoGatePolicy(
        freeLimits: [Gate.members: freeMembers, Gate.laws: freeLaws],
        proOnly: [Gate.siri, Gate.courtName]
    )

    // MARK: - 먼저 써 준 가족

    /// 모든 기능이 무료였던 마지막 빌드(1.0.3 빌드 6). 이 빌드까지 받은 사람은 Pro 평생이다.
    static let lastFreeBuild = 6

    private static let legacyKey = "pro.legacyInstall"

    /// 이 빌드를 처음 켤 때 한 번만 적는다: 그때 이미 식구 · 사건이 있었는가.
    /// 오프라인이라 영수증(`AppTransaction`)을 못 읽어도 먼저 쓰던 가족이 잠기지 않게 하는 두 번째 끈이다.
    static func noteFirstLaunch(hadRecords: Bool) {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: legacyKey) == nil else { return }
        defaults.set(hadRecords, forKey: legacyKey)
    }

    /// 유료 칸이 생기기 전에 받은 사람인가.
    @MainActor
    static func isLegacyInstall() async -> Bool {
        if UserDefaults.standard.bool(forKey: legacyKey) { return true }
        // 처음 받은 빌드 번호. 샌드박스 · TestFlight 는 "1.0" 이라 숫자가 아니므로 여기서 걸리지 않는다.
        guard case .verified(let app) = try? await AppTransaction.shared,
              let build = Int(app.originalAppVersion) else { return false }
        return build <= lastFreeBuild
    }

    // MARK: - 팔기 시작했는가

    private static let onSaleKey = "plans.onSale"

    /// **팔기 시작했는가.** Pro 상품을 하나도 못 불러온 기기는 한도로 막지 않는다 (→ `LeeoStore.limits`).
    /// ⚠️ App Store Connect 에 상품이 서기 전에 빌드가 나가면, 살 수 없는데 막히는 사람이 생긴다.
    ///    한 번이라도 불러온 기기는 기억해 둔다 — 그 뒤로 잠깐 오프라인이어도 다시 한도가 선다.
    static var isSelling: Bool { UserDefaults.standard.bool(forKey: onSaleKey) }

    /// 불러온 상품에 Pro 상품이 있으면 적어 둔다. 앱이 상품 목록이 바뀔 때마다 부른다.
    static func noteProducts(_ products: [Product]) {
        guard !isSelling, products.contains(where: { productIDs.contains($0.id) }) else { return }
        UserDefaults.standard.set(true, forKey: onSaleKey)
    }

    // MARK: -

    @MainActor
    static func makeStore() -> LeeoStore {
        guard let config = FamilyCourtSpec.paywall else {
            preconditionFailure("계약에 페이월이 없다. FamilyCourtSpec.monetization 을 확인할 것")
        }
        return LeeoStore(config: config, grandfather: { await isLegacyInstall() })
    }
}

extension LeeoStore {
    /// 무료 한도 판정기. 화면은 `gate` 대신 이것을 본다 — 팔기 전(`Pro.isSelling`)이면 아무것도 막지 않는다.
    var limits: LeeoGate { LeeoGate(policy: config.gate, hasPro: hasPro || !Pro.isSelling) }
}

// MARK: - 잠긴 자리

/// 페이월이 뜬 까닭. 어른 확인 화면의 그림과 페이월 첫 줄이 여기서 온다.
enum ProLock: String, Identifiable {
    case members, laws, siri, courtName
    /// 설정 · 판결 화면에서 스스로 열어 본 것
    case browse
    /// 구독 중인 사람의 구독 졸업 평생가
    case graduate

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .members: "person.3.fill"
        case .laws: "book.closed.fill"
        case .siri: "mic.fill"
        case .courtName: "building.columns.fill"
        case .browse: "crown.fill"
        case .graduate: "graduationcap.fill"
        }
    }

    /// 방금 부딪힌 한도. 스스로 열어 본 것이면 nil.
    var message: String? {
        switch self {
        case .members:
            String(localized: "가족 등록부는 \(Pro.freeMembers)명까지 무료예요. Pro면 할머니 · 할아버지 · 사촌까지 모두 법정에 불러요.",
                   comment: "Paywall reason: family member limit reached. %lld = free member limit")
        case .laws:
            String(localized: "우리 집 법전은 \(Pro.freeLaws)조까지 무료예요. Pro면 가족회의에서 만든 법을 끝없이 더해요.",
                   comment: "Paywall reason: house law limit reached. %lld = free law limit")
        case .siri:
            String(localized: "Siri와 단축어로 바로 접수하는 건 Pro에서 열려요. 앱에서 접수하는 건 언제나 무료예요.",
                   comment: "Paywall reason: Siri / Shortcuts are Pro")
        case .courtName:
            String(localized: "우리 집 법원 이름은 Pro에서 정할 수 있어요.",
                   comment: "Paywall reason: naming the court is Pro")
        case .browse, .graduate:
            nil
        }
    }
}
