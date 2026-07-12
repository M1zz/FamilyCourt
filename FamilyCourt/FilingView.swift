import SwiftUI

/// 소송 접수 — 접수하는 사람(원고·검사)이 상대와 판사를 직접 정해요.
struct FilingView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    let type: CaseType
    var onFiled: (String) -> Void

    @State private var title = ""
    @State private var accuser = ""
    @State private var accused = ""
    @State private var judge = ""
    @State private var desc = ""
    @State private var want = ""
    @State private var pickedLaws: Set<String> = []
    @State private var alertMessage: String?

    private var judgeCandidates: [Member] {
        store.data.members.filter { $0.id != accuser && $0.id != accused }
    }

    var body: some View {
        NavigationStack {
            Form {
                if store.data.members.count < 3 {
                    Section {
                        Label("재판을 열려면 가족이 3명 이상 필요해요 (판사도 필요해요!). [가족] 탭에서 먼저 등록해 주세요.",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                }

                Section(header: Text("사건 제목"), footer: Text(store.vocab.fileHint(type))) {
                    TextField("예: 내 과자를 몰래 먹은 사건", text: $title)
                }

                Section(header: Text("참여자 정하기"),
                        footer: Text(store.vocab.judgeFieldFooter)) {
                    memberPicker(store.vocab.accuserFieldLabel(type), selection: $accuser)
                    memberPicker(store.vocab.accusedFieldLabel(type), selection: $accused)
                    Picker(store.vocab.judgeFieldLabel, selection: $judge) {
                        Text("골라 주세요").tag("")
                        ForEach(judgeCandidates) { m in
                            Text("\(m.emoji) \(m.name)").tag(m.id)
                        }
                    }
                }

                Section("무슨 일이 있었나요?") {
                    TextEditor(text: $desc)
                        .frame(minHeight: 90)
                        .overlay(alignment: .topLeading) {
                            if desc.isEmpty {
                                Text("언제, 어디서, 무슨 일이 있었는지 자세히 써 주세요.")
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section(header: Text("어긴 법 고르기"),
                        footer: type == .criminal ? Text("형사 소송은 어긴 법을 꼭 골라야 해요.") : nil) {
                    ForEach(Array(store.data.laws.enumerated()), id: \.element.id) { index, law in
                        Button {
                            if pickedLaws.contains(law.id) { pickedLaws.remove(law.id) }
                            else { pickedLaws.insert(law.id) }
                        } label: {
                            HStack {
                                Text("제\(index + 1)조 \(law.title)").foregroundColor(.primary)
                                Spacer()
                                if pickedLaws.contains(law.id) {
                                    Image(systemName: "checkmark").foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                Section(store.vocab.wantLabel(type)) {
                    TextField(type.wantPrompt, text: $want)
                }

                Section {
                    Button {
                        submit()
                    } label: {
                        Text("📩 접수하고 소송 시작!")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("\(type.badgeEmoji) \(store.vocab.fileTitle(type))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .onChange(of: accuser) { _ in clearJudgeIfInvalid() }
            .onChange(of: accused) { _ in clearJudgeIfInvalid() }
            .alert("잠깐만요!", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("알겠어요", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func memberPicker(_ label: String, selection: Binding<String>) -> some View {
        Picker(label, selection: selection) {
            Text("골라 주세요").tag("")
            ForEach(store.data.members) { m in
                Text("\(m.emoji) \(m.name)").tag(m.id)
            }
        }
    }

    private func clearJudgeIfInvalid() {
        if judge == accuser || judge == accused { judge = "" }
    }

    private func submit() {
        let v = store.vocab
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        if store.data.members.count < 3 {
            alertMessage = "먼저 [가족] 탭에서 가족을 3명 이상 등록해 주세요 (\(v.judge)도 필요해요!)"
            return
        }
        if trimmedTitle.isEmpty { alertMessage = "사건 제목을 써 주세요"; return }
        if accuser.isEmpty || accused.isEmpty {
            alertMessage = "\(v.wa(v.accuser(type))) \(v.eul(v.accused(type))) 골라 주세요"; return
        }
        if accuser == accused {
            alertMessage = "\(v.wa(v.accuser(type))) \(v.neun(v.accused(type))) 다른 사람이어야 해요"; return
        }
        if judge.isEmpty { alertMessage = "\(v.eul(v.judge)) 골라 주세요"; return }
        if judge == accuser || judge == accused {
            alertMessage = "\(v.neun(v.judge)) 사건과 관련 없는 사람이어야 해요"; return
        }
        if type == .criminal && pickedLaws.isEmpty {
            alertMessage = "형사 소송은 어긴 법을 꼭 골라야 해요"; return
        }

        let orderedLaws = store.data.laws.map(\.id).filter { pickedLaws.contains($0) }
        let newId = store.fileCase(
            type: type,
            title: trimmedTitle,
            desc: desc.trimmingCharacters(in: .whitespacesAndNewlines),
            want: want.trimmingCharacters(in: .whitespaces),
            lawIds: orderedLaws,
            judge: judge, accuser: accuser, accused: accused
        )
        dismiss()
        onFiled(newId)
    }
}
