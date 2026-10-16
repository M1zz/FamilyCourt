import SwiftUI

/// 첫 실행 안내 — 이 법원이 어떻게 움직이는지 네 장으로 보여 줘요.
/// 다 보면 `hasSeenOnboarding` 이 켜지고, 설정의 [사용법 다시 보기]로 언제든 다시 열 수 있어요.
/// 스크린샷 촬영 때는 실행 인자 `-hasSeenOnboarding YES` 로 건너뛴다.
struct FamilyCourtOnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private struct Page {
        let emoji: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(emoji: "⚖️",
             title: "우리 집 가정법원에\n오신 걸 환영해요",
             body: "억울한 일도, 약속을 어긴 일도\n가족이 함께 여는 재판으로 풀어요.\n서로의 이야기를 끝까지 듣는 연습이 돼요."),
        Page(emoji: "👨‍👩‍👧",
             title: "먼저 가족을 등록해요",
             body: "[가족] 탭에서 재판에 함께할 가족을 추가해요.\n누구든 사건에 따라 판사도, 원고도,\n변호인도 될 수 있어요."),
        Page(emoji: "😤",
             title: "억울하면 직접 접수해요",
             body: "[법원] 탭에서 억울한 일은 민사로,\n우리 집 법을 어긴 일은 형사로 접수해요.\n누구를 부를지, 누가 판사를 볼지도 직접 정해요."),
        Page(emoji: "🔨",
             title: "대본을 따라 재판해요",
             body: "단계별 대본과 타이머, 의사봉이\n재판을 도와줘요.\n판결이 나면 꼭 서로 안아주고 화해해요 🤗")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("건너뛰기") { onFinish() }
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .opacity(page == pages.count - 1 ? 0 : 1)
                    .disabled(page == pages.count - 1)
            }

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 20) {
                        Spacer()
                        Text(pages[i].emoji)
                            .font(.system(size: 88))
                            .accessibilityHidden(true)
                        Text(pages[i].title)
                            .font(.system(size: 26, weight: .bold))
                            .multilineTextAlignment(.center)
                        Text(pages[i].body)
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        Spacer()
                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(page < pages.count - 1 ? "다음" : "재판 시작하기")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
