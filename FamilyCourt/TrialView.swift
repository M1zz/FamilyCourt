import SwiftUI

/// 재판 세션 — 역할 확인 → 재판 진행 → 판결 선고까지 한 번에 진행해요.
struct TrialFlowView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    let caseId: String

    private enum Phase { case prep, run, verdict }
    #if DEBUG
    @State private var phase: Phase = ScreenshotScene.current == .trial ? .run : .prep
    #else
    @State private var phase: Phase = .prep
    #endif

    var body: some View {
        NavigationStack {
            if let c = store.courtCase(caseId) {
                switch phase {
                case .prep:
                    TrialPrepView(courtCase: c) {
                        phase = .run
                    } onCancel: {
                        dismiss()
                    }
                case .run:
                    TrialRunView(courtCase: c) {
                        phase = .verdict
                    } onPause: {
                        store.update(caseId) { $0.status = .waiting }
                        dismiss()
                    }
                case .verdict:
                    VerdictFormView(courtCase: c) {
                        dismiss()
                    }
                }
            } else {
                Text("사건을 찾을 수 없어요").foregroundColor(.secondary)
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - 1단계: 역할 확인 (피고는 변호인을 고를 수 있어요)

struct TrialPrepView: View {
    @EnvironmentObject var store: Store

    let courtCase: CourtCase
    var onStart: () -> Void
    var onCancel: () -> Void

    @State private var lawyer = ""
    @State private var clerk = ""

    private var helperCandidates: [Member] {
        store.data.members.filter {
            $0.id != courtCase.roles.judge &&
            $0.id != courtCase.roles.accuser &&
            $0.id != courtCase.roles.accused
        }
    }

    var body: some View {
        Form {
            Section(header: Text("이 사건의 역할"),
                    footer: Text("역할은 재판을 신청한 사람이 이미 정했어요. 재판에 넘겨지는 사람은 자기를 도와줄 \(store.vocab.eul(store.vocab.lawyer)) 고를 수 있어요!")) {
                RoleRow(role: "👨‍⚖️ \(store.vocab.judge)", name: store.memName(courtCase.roles.judge))
                RoleRow(role: "\(courtCase.type.accuserEmoji) \(store.vocab.accuser(courtCase.type))",
                        name: store.memName(courtCase.roles.accuser))
                RoleRow(role: "\(courtCase.type.accusedEmoji) \(store.vocab.accused(courtCase.type))",
                        name: store.memName(courtCase.roles.accused))
            }

            Section("도와주는 역할 (없어도 돼요)") {
                Picker("🛡️ " + store.vocab.lawyer, selection: $lawyer) {
                    Text("— 없음 —").tag("")
                    ForEach(helperCandidates) { m in
                        Text(verbatim: "\(m.emoji) \(m.name)").tag(m.id)
                    }
                }
                Picker("✍️ " + store.vocab.clerk, selection: $clerk) {
                    Text("— 없음 —").tag("")
                    ForEach(store.data.members.filter {
                        $0.id != courtCase.roles.accuser && $0.id != courtCase.roles.accused
                    }) { m in
                        Text(verbatim: "\(m.emoji) \(m.name)").tag(m.id)
                    }
                }
            }

            Section {
                Button {
                    store.update(courtCase.id) {
                        $0.roles.lawyer = lawyer
                        $0.roles.clerk = clerk
                        $0.status = .inTrial
                    }
                    SoundPlayer.shared.gavel()
                    onStart()
                } label: {
                    Label("재판 시작!", systemImage: "hammer.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("🎭 역할 확인")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("닫기") { onCancel() }
            }
        }
        .onAppear {
            lawyer = courtCase.roles.lawyer
            clerk = courtCase.roles.clerk
        }
    }
}

// MARK: - 2단계: 재판 진행 (대본 · 타이머 · 의사봉)

struct TrialRunView: View {
    @EnvironmentObject var store: Store

    let courtCase: CourtCase
    var onFinish: () -> Void
    var onPause: () -> Void

    @State private var stepIdx = 0
    @State private var remaining = 0
    @State private var timerOn = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var steps: [TrialStep] { store.trialSteps(for: courtCase) }

    var body: some View {
        let step = steps[min(stepIdx, steps.count - 1)]

        VStack(spacing: 14) {
            // 진행 점
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Circle()
                        .fill(i < stepIdx ? Color.green : (i == stepIdx ? Color.blue : Color(.systemFill)))
                        .frame(width: 8, height: 8)
                        .scaleEffect(i == stepIdx ? 1.3 : 1)
                }
            }
            .padding(.top, 6)
            // 점 색 대신 "몇 번째 단계"로 읽어 준다
            .accessibilityElement()
            .accessibilityLabel(Text("진행"))
            .accessibilityValue(Text(verbatim: "\(stepIdx + 1)/\(steps.count)"))

            // 지금 말할 사람
            Text(step.role)
                .scaledFont(14, weight: .bold, relativeTo: .subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.14))
                .clipShape(Capsule())

            Text(verbatim: "\(stepIdx + 1). \(step.title)")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                Text(step.script)
                    .scaledFont(16, relativeTo: .callout)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)

                if step.timer != nil {
                    timerView
                }

                if step.gavel {
                    gavelView
                }
            }

            // 이전 / 다음
            HStack(spacing: 10) {
                Button {
                    move(-1)
                } label: {
                    Text("← 이전").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .opacity(stepIdx == 0 ? 0 : 1)
                .disabled(stepIdx == 0)
                .accessibilityHidden(stepIdx == 0)
                .accessibilityLabel(Text("이전"))

                Button {
                    move(1)
                } label: {
                    Group {
                        if stepIdx == steps.count - 1 { Text("판결 내리러 가기 📜") } else { Text("다음 →") }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(stepIdx == steps.count - 1 ? Text("판결 내리러 가기 📜") : Text("다음"))
            }
            .padding(.horizontal, 16)

            Button(role: .destructive) {
                onPause()
            } label: {
                Text("재판 잠시 멈추기")
                    .font(.footnote)
            }
            .padding(.bottom, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(courtCase.caseNo)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { resetTimer() }
        .onChange(of: stepIdx) { _ in resetTimer() }
        .onReceive(ticker) { _ in
            guard timerOn, remaining > 0 else { return }
            remaining -= 1
            if remaining == 0 {
                timerOn = false
                SoundPlayer.shared.beep()
            }
        }
    }

    private var timerView: some View {
        VStack(spacing: 8) {
            Text(timeText)
                .scaledFont(56, weight: .bold, design: .rounded, relativeTo: .largeTitle)
                .monospacedDigit()
                .foregroundColor(remaining <= 10 && remaining > 0 && timerOn ? .red : .primary)
                .accessibilityLabel("남은 시간")
                .accessibilityValue("\(remaining / 60)분 \(remaining % 60)초")
            HStack(spacing: 8) {
                Button {
                    if !timerOn && remaining == 0 { resetTimer() }
                    timerOn.toggle()
                } label: {
                    if timerOn { Text("⏸ 멈춤") } else { Text("▶ 시작") }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(timerOn ? Text("타이머 멈추기") : Text("타이머 시작"))
                Button("↺ 다시") {
                    timerOn = false
                    resetTimer()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("타이머 처음부터")
                Button("+30초") { remaining += 30 }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("30초 더하기")
            }
            .scaledFont(14, weight: .semibold, relativeTo: .subheadline)
        }
        .padding(.top, 12)
    }

    private var gavelView: some View {
        VStack(spacing: 6) {
            Button {
                SoundPlayer.shared.gavel()
            } label: {
                Text("🔨")
                    .scaledFont(40, relativeTo: .largeTitle)
                    .minimumScaleFactor(0.5)
                    .frame(width: 88, height: 88)
                    .background(Color.blue.opacity(0.14))
                    .clipShape(Circle())
            }
            .accessibilityLabel("의사봉 두드리기")
            Text("의사봉을 눌러 보세요! (탕탕탕)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 12)
    }

    private var timeText: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private func resetTimer() {
        timerOn = false
        remaining = steps[min(stepIdx, steps.count - 1)].timer ?? 0
    }

    private func move(_ delta: Int) {
        let next = stepIdx + delta
        if next < 0 { return }
        if next >= steps.count {
            timerOn = false
            onFinish()
            return
        }
        stepIdx = next
    }
}

// MARK: - 3단계: 판결 선고

struct VerdictFormView: View {
    @EnvironmentObject var store: Store

    let courtCase: CourtCase
    var onDone: () -> Void

    @State private var result = ""
    @State private var text = ""
    @State private var penalty = ""
    @State private var showEmptyAlert = false
    @State private var showSuggestions = false

    var body: some View {
        Form {
            Section(header: Text(store.vocab.verdictResultLabel),
                    footer: Text("\(store.vocab.ga(store.vocab.judge)) 양쪽 이야기를 잘 듣고 공정하게 정해요.")) {
                Picker("결과", selection: $result) {
                    ForEach(store.vocab.verdictOptions(courtCase.type)) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section(store.vocab.verdictTextLabel) {
                TextEditor(text: $text)
                    .accessibilityLabel(Text(verbatim: store.vocab.verdictTextLabel))
                    .frame(minHeight: 100)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("예: 내 과자를 허락 없이 먹어 제2조를 어겼으므로...")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section(header: Text(store.vocab.penaltyLabel(courtCase.type)),
                    footer: Text("벌칙은 짧고 지킬 수 있게! \(store.vocab.ga(store.vocab.accused(courtCase.type))) 스스로 제안한 벌칙이 가장 잘 지켜져요.")) {
                TextField(penaltyPrompt, text: $penalty)
                Button {
                    showSuggestions = true
                } label: {
                    Label("추천 벌칙 보기", systemImage: "lightbulb.fill")
                }
            }

            Section {
                Button {
                    saveVerdict()
                } label: {
                    Label("판결 확정 (탕탕탕!)", systemImage: "hammer.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle(store.vocab.verdictFormTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if result.isEmpty {
                result = store.vocab.verdictOptions(courtCase.type).first?.value ?? ""
            }
        }
        .alert("판결문을 써 주세요", isPresented: $showEmptyAlert) {
            Button("알겠어요", role: .cancel) {}
        }
        .sheet(isPresented: $showSuggestions) {
            PenaltySuggestionsView { picked in
                penalty = picked
            }
        }
    }

    private var penaltyPrompt: String {
        guard courtCase.type == .criminal, !courtCase.want.isEmpty else {
            return String(localized: "예: 사과 편지 쓰기, 설거지 3번 돕기")
        }
        let v = store.vocab
        return String(localized: "\(v.accuser(.criminal))의 \(v.wantShort(.criminal)): \(courtCase.want)",
                      comment: "Placeholder: prosecutor's demanded penalty")
    }

    private func saveVerdict() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showEmptyAlert = true
            return
        }
        store.update(courtCase.id) {
            $0.verdict = Verdict(
                result: result,
                text: trimmed,
                penalty: penalty.trimmingCharacters(in: .whitespaces),
                penaltyDone: false,
                decidedAt: store.todayString(),
                judge: $0.roles.judge
            )
            $0.status = .decided
        }
        SoundPlayer.shared.gavel()
        onDone()
    }
}

// MARK: - 추천 벌칙 고르기 (처벌보다 회복이 먼저!)

struct PenaltySuggestionsView: View {
    @Environment(\.dismiss) private var dismiss
    var onPick: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("좋은 벌칙은 잘못을 되돌리고 마음을 회복하는 거예요. 위에 있을수록 교육 효과가 커요. 골라서 우리 집에 맞게 고쳐 써도 좋아요!")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                ForEach(PenaltyCategory.all) { category in
                    Section(header: Text(verbatim: "\(category.emoji) \(category.title)"),
                            footer: Text(category.hint)) {
                        ForEach(category.items, id: \.self) { item in
                            Button {
                                onPick(item)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(item)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .accessibilityHint("이 벌칙을 판결에 넣어요")
                        }
                    }
                }
            }
            .navigationTitle("💡 추천 벌칙")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}
