//
//  UnlockSheet.swift
//  FamilyCourt
//
//  잠긴 자리에서 뜨는 시트: 먼저 어른 확인, 그 뒤에만 결제 화면(팔랑북 UnlockSheet 방식).
//  아이가 스스로 가격 앞에 서는 일은 없다.
//
//  ⚠️ 결제는 `@Environment(\.purchase)` 로 한다. `product.purchase()` 는 결제 시트를 띄울 창을
//     짐작하다 아이패드에서 빗나가 심사 2.1(b) 거절을 낸 적이 있다(다른 앱).
//

import SwiftUI
import StoreKit
import LeeoKit

extension View {
    /// `lock` 이 서면 어른 확인 → 페이월 시트를 띄운다.
    func unlockSheet(_ lock: Binding<ProLock?>) -> some View {
        sheet(item: lock) { UnlockSheet(reason: $0) }
    }
}

struct UnlockSheet: View {
    let reason: ProLock

    @EnvironmentObject private var pro: LeeoStore
    @Environment(\.dismiss) private var dismiss
    @State private var grownUp = false

    var body: some View {
        Group {
            if !grownUp {
                ParentGateView(icon: reason.icon) { withAnimation { grownUp = true } }
            } else if reason == .graduate {
                LeeoGraduationOfferView(graduate: pro.products.first { $0.id == Pro.graduateID }) {
                    await pro.refreshEntitlements()
                }
                .task { await pro.loadProducts() }
            } else {
                ProPaywallView(reason: reason)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .padding(16)
            }
            .accessibilityLabel(Text("닫기"))
        }
        // 산 순간 닫는다. 졸업가는 산 뒤 구독 해지 안내가 남아야 하므로 닫지 않는다.
        .onChange(of: pro.hasPro) { _, hasPro in
            if hasPro, reason != .graduate { dismiss() }
        }
    }
}

// MARK: - 어른 확인

/// 글을 막 깨친 아이는 못 푸는 곱셈을 숫자판으로 받는다(찍어서 맞히기 어렵게).
/// 틀리면 새 문제로 바뀐다.
struct ParentGateView: View {
    /// 무엇이 잠겼는지 보여 주는 큰 그림 — 아이가 왜 멈췄는지 안다.
    let icon: String
    let onPass: () -> Void

    @State private var a = Int.random(in: 6...9)
    @State private var b = Int.random(in: 6...9)
    @State private var answer = ""
    @State private var shake = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 56))
                        .foregroundStyle(.blue)
                        .frame(width: 112, height: 112)
                        .background(Circle().fill(Color.blue.opacity(0.12)))
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(Color.gray))
                }
                .accessibilityHidden(true)
                .padding(.top, 48)

                VStack(spacing: 8) {
                    Text("어른에게 보여 주세요")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("보호자 확인: 아래 문제의 답을 눌러 주세요.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 14) {
                    Text(verbatim: "\(a) × \(b) =")
                    Text(verbatim: answer.isEmpty ? "?" : answer)
                        .frame(minWidth: 72)
                        .foregroundStyle(answer.isEmpty ? .secondary : .primary)
                }
                .font(.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit())
                .modifier(Shake(animatableData: CGFloat(shake)))
                .accessibilityElement(children: .combine)

                keypad
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }

    private var keypad: some View {
        let rows: [[String]] = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["⌫", "0", "✓"]]
        return VStack(spacing: 10) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        Button { press(key) } label: {
                            Group {
                                switch key {
                                case "⌫": Image(systemName: "delete.left")
                                        .accessibilityLabel(Text("한 칸 지우기"))
                                case "✓": Image(systemName: "checkmark")
                                        .accessibilityLabel(Text("확인"))
                                default: Text(verbatim: key)
                                }
                            }
                            .font(.system(.title, design: .rounded).weight(.semibold))
                            .frame(maxWidth: 96, minHeight: 56)
                        }
                        .buttonStyle(.bordered)
                        .tint(key == "✓" ? .green : .primary)
                    }
                }
            }
        }
    }

    private func press(_ key: String) {
        switch key {
        case "⌫":
            if !answer.isEmpty { answer.removeLast() }
        case "✓":
            if Int(answer) == a * b {
                onPass()
            } else {
                withAnimation(.default) { shake += 1 }
                answer = ""
                a = Int.random(in: 6...9)
                b = Int.random(in: 6...9)
            }
        default:
            if answer.count < 3 { answer += key }
        }
    }
}

private struct Shake: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 12 * sin(animatableData * .pi * 4), y: 0))
    }
}

// MARK: - 페이월 (어른이 보는 화면)

/// 무료 · Pro 비교표와 Pro 를 사는 네 가지 길. 연 구독을 먼저 고르고, 주 · 월은 펼쳐 보인다.
/// 스토어에서 불러온 상품만 세운다 — 아직 없는 상품의 단추는 그리지 않는다.
private struct ProPaywallView: View {
    let reason: ProLock

    @EnvironmentObject private var pro: LeeoStore
    @Environment(\.purchase) private var purchaseAction
    @State private var plan: Plan
    @State private var showsShortTerms = false
    @State private var introEligible = false
    @State private var restoredNothing = false

    init(reason: ProLock) {
        self.reason = reason
        // 법전이 길어진 집은 오래 쓸 집이다 — 평생을 먼저 보인다. 나머지는 연 구독.
        _plan = State(initialValue: reason == .laws ? .lifetime : .yearly)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                ComparisonTable()
                plans
                footer
            }
            .padding(20)
            .padding(.top, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .task {
            LeeoAnalyticsCenter.track(.paywallShown(reason: reason.rawValue))
            await pro.loadProducts()
            if product(plan) == nil, let first = Plan.allCases.first(where: { product($0) != nil }) { plan = first }
            introEligible = await product(.yearly)?.subscription?.isEligibleForIntroOffer ?? false
        }
    }

    private func product(_ plan: Plan) -> Product? {
        pro.products.first { $0.id == plan.productID }
    }

    // MARK: 머리

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("억울해요 Pro")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            if let message = reason.message {
                Text(message)
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            Text("재판은 언제나 무료예요. 식구가 많고 법이 많은 집을 위한 Pro를 연 구독이나 평생으로 고르세요.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: 고르기

    @ViewBuilder
    private var plans: some View {
        let main = [Plan.yearly, .lifetime].filter { product($0) != nil }
        let short = [Plan.monthly, .weekly].filter { product($0) != nil }

        if main.isEmpty && short.isEmpty {
            VStack(spacing: 12) {
                if pro.isLoadingProducts {
                    ProgressView()
                } else {
                    Text(pro.lastError ?? String(localized: "상품을 불러오지 못했어요."))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("다시 시도") { Task { await pro.loadProducts() } }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        } else {
            VStack(spacing: 10) {
                ForEach(main, id: \.self) { option($0) }
                if !short.isEmpty {
                    if showsShortTerms || short.contains(plan) {
                        ForEach(short, id: \.self) { option($0) }
                    } else {
                        Button("다른 기간 보기") { withAnimation { showsShortTerms = true } }
                            .padding(.vertical, 4)
                    }
                }
                if let note {
                    Text(note)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                buyButton
                if product(plan)?.isFamilyShareable == true {
                    Label("가족 공유로 온 가족이 함께 써요", systemImage: "person.3.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                if let error = pro.lastError {
                    Text(error)
                        .font(.body)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private func option(_ value: Plan) -> some View {
        let selected = plan == value
        return Button { plan = value } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Color.accentColor : .secondary)
                    .accessibilityHidden(true)
                Text(value.title)
                    .font(.headline)
                Spacer(minLength: 8)
                Text(product(value).map(value.price) ?? "")
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
            }
            .foregroundStyle(.primary)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// 고른 길 아래 한 줄: 연 구독은 첫 해 할인, 평생은 "연 구독 N년치".
    private var note: String? {
        switch plan {
        case .yearly:
            guard introEligible, let offer = product(.yearly)?.subscription?.introductoryOffer,
                  offer.paymentMode == .payUpFront || offer.paymentMode == .payAsYouGo else { return nil }
            return String(format: LeeoLadderText.introFormat, offer.displayPrice)
        case .lifetime:
            guard let yearly = product(.yearly)?.price, let lifetime = product(.lifetime)?.price, yearly > 0 else { return nil }
            let years = Int(NSDecimalNumber(decimal: lifetime / yearly).doubleValue.rounded(.down))
            return years >= 2 ? String(format: LeeoLadderText.lifetimeWorthFormat, years) : nil
        case .monthly, .weekly:
            return nil
        }
    }

    private var buyButton: some View {
        Button {
            guard let product = product(plan) else { return }
            Task { await pro.purchase(product) { try await purchaseAction($0) } }
        } label: {
            Group {
                if pro.purchasingProductID != nil {
                    ProgressView().tint(.white)
                } else {
                    Text("Pro 열기").font(.title3.bold())
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.accentColor))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(product(plan) == nil || pro.purchasingProductID != nil)
        .padding(.top, 6)
    }

    // MARK: 아래

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await pro.restore()
                    restoredNothing = !pro.hasPro && pro.lastError == nil
                }
            } label: {
                if pro.isRestoring { ProgressView() } else { Text("구매 복원") }
            }
            .disabled(pro.isRestoring)
            if restoredNothing {
                Text("이 Apple 계정에서 구매한 기록을 찾지 못했어요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("구독은 기간이 끝나기 24시간 전까지 해지하지 않으면 같은 값으로 자동 갱신돼요. 결제는 Apple 계정으로 청구되고, 기기의 Apple 계정 설정에서 언제든 해지할 수 있어요. 평생은 한 번만 결제해요.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 20) {
                if let terms = FamilyCourtSpec.monetization.subscriptionTermsURL {
                    Link("이용약관", destination: terms)
                }
                Link("개인정보처리방침", destination: FamilyCourtSpec.legal.privacyURL)
            }
            .font(.body)
        }
    }
}

/// Pro 를 사는 길. 졸업가는 여기 없다 — 구독 중인 사람에게만 따로 보인다.
private enum Plan: CaseIterable {
    case yearly, lifetime, monthly, weekly

    var productID: String {
        switch self {
        case .yearly: Pro.yearlyID
        case .lifetime: Pro.lifetimeID
        case .monthly: Pro.monthlyID
        case .weekly: Pro.weeklyID
        }
    }

    var title: String {
        switch self {
        case .yearly: LeeoLadderText.yearly
        case .lifetime: LeeoLadderText.lifetime
        case .monthly: String(localized: "월 구독", comment: "Paywall plan: monthly subscription")
        case .weekly: String(localized: "주 구독", comment: "Paywall plan: weekly subscription")
        }
    }

    func price(_ product: Product) -> String {
        switch self {
        case .yearly: String(format: LeeoLadderText.perYearFormat, product.displayPrice)
        case .lifetime: product.displayPrice
        case .monthly: String(localized: "\(product.displayPrice) / 월", comment: "Paywall plan: monthly price. %@ = price")
        case .weekly: String(localized: "\(product.displayPrice) / 주", comment: "Paywall plan: weekly price. %@ = price")
        }
    }
}

// MARK: - 비교표

/// 무료와 Pro 가 무엇이 다른가. 위 다섯 줄은 둘 다 열려 있다 — 재판은 언제나 무료다.
private struct ComparisonTable: View {
    private enum Cell { case yes, no, text(String) }

    private var rows: [(String, Cell, Cell)] {
        let unlimited = String(localized: "무제한", comment: "Paywall table: no limit")
        return [
            (String(localized: "재판 열기 (민사 · 형사)", comment: "Paywall table row"), .text(unlimited), .text(unlimited)),
            (String(localized: "역할 · 대본 · 타이머", comment: "Paywall table row"), .yes, .yes),
            (String(localized: "판결 · 벌칙 추천 · 약속 체크", comment: "Paywall table row"), .yes, .yes),
            (String(localized: "어휘 난이도", comment: "Paywall table row"), .yes, .yes),
            (String(localized: "지난 사건 · 백업", comment: "Paywall table row"), .yes, .yes),
            (String(localized: "가족 구성원", comment: "Paywall table row"),
             .text(String(localized: "\(Pro.freeMembers)명", comment: "Paywall table: free member limit. %lld = count")), .text(unlimited)),
            (String(localized: "법전 조문", comment: "Paywall table row"),
             .text(String(localized: "\(Pro.freeLaws)조", comment: "Paywall table: free law limit. %lld = count")), .text(unlimited)),
            (String(localized: "Siri · 단축어", comment: "Paywall table row"), .no, .yes),
            (String(localized: "법원 이름 정하기", comment: "Paywall table row"), .no, .yes),
        ]
    }

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                Text("무료", comment: "Paywall table column: free")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .gridColumnAlignment(.center)
                Text(verbatim: "Pro")
                    .font(.headline)
                    .foregroundStyle(.orange)
                    .gridColumnAlignment(.center)
            }
            .accessibilityHidden(true)
            Divider()
            ForEach(rows, id: \.0) { title, free, pro in
                GridRow {
                    Text(title)
                        .fixedSize(horizontal: false, vertical: true)
                    cell(free)
                    cell(pro)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: "\(title), \(String(localized: "무료", comment: "Paywall table column: free")) \(spoken(free)), Pro \(spoken(pro))"))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
    }

    @ViewBuilder
    private func cell(_ cell: Cell) -> some View {
        switch cell {
        case .yes:
            Image(systemName: "checkmark").font(.body.weight(.bold)).foregroundStyle(.green)
        case .no:
            Image(systemName: "minus").foregroundStyle(.secondary)
        case .text(let s):
            Text(s).font(.body.weight(.semibold)).multilineTextAlignment(.center)
        }
    }

    private func spoken(_ cell: Cell) -> String {
        switch cell {
        case .yes: String(localized: "포함", comment: "VoiceOver: paywall table cell, included")
        case .no: String(localized: "없음", comment: "VoiceOver: paywall table cell, not included")
        case .text(let s): s
        }
    }
}

// MARK: - 설정 ▸ 억울해요 Pro

/// Pro 를 알아보거나, 쓰고 있다면 구독 관리 · 평생으로 바꾸기 · 구매 복원.
struct ProSettingsSection: View {
    @Binding var lock: ProLock?

    @EnvironmentObject private var pro: LeeoStore
    @State private var subscription: LeeoGraduation.Subscription?
    @State private var showsManage = false
    @State private var restoredNothing = false

    var body: some View {
        Section {
            if pro.hasPro {
                Label("Pro를 쓰고 있어요", systemImage: "crown.fill")
                if pro.isGrandfathered, pro.purchasedProductIDs.isDisjoint(with: Pro.productIDs) {
                    Text("먼저 써 주신 가족이라 Pro가 평생 열려 있어요.")
                        .foregroundStyle(.secondary)
                }
                if subscription != nil {
                    Button("구독 관리") { showsManage = true }
                    // 구독 중인 사람에게 늘 서는 줄. 졸업가 상품이 스토어에 있을 때만.
                    if pro.products.contains(where: { $0.id == Pro.graduateID }) {
                        Button(LeeoLadderText.switchToLifetimeEntry) { lock = .graduate }
                    }
                }
            } else {
                Button { lock = .browse } label: {
                    Label("억울해요 Pro 알아보기", systemImage: "crown.fill")
                }
            }
            Button {
                Task {
                    await pro.restore()
                    restoredNothing = !pro.hasPro && pro.lastError == nil
                }
            } label: {
                if pro.isRestoring { ProgressView() } else { Text("구매 복원") }
            }
            .disabled(pro.isRestoring)
            if restoredNothing {
                Text("이 Apple 계정에서 구매한 기록을 찾지 못했어요.")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("억울해요 Pro")
        }
        .task(id: pro.purchasedProductIDs) {
            subscription = await LeeoGraduation.currentSubscription(among: Pro.subscriptionIDs)
            if subscription != nil { await pro.loadProducts() }
        }
        .manageSubscriptionsSheet(isPresented: $showsManage)
    }
}
