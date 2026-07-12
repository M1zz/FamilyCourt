import SwiftUI
import UniformTypeIdentifiers

// MARK: - 법전

struct LawsView: View {
    @EnvironmentObject var store: Store
    @State private var editingLaw: Law?
    @State private var showAdd = false

    var body: some View {
        List {
            Section(footer: Text("가족 모두가 함께 정한 우리 집의 법이에요. 형사 소송은 이 법전의 법을 어겼을 때 열 수 있어요. 가족회의에서 모두 동의하면 법을 만들거나 고칠 수 있어요.")) {
                if store.data.laws.isEmpty {
                    EmptyNotice(emoji: "📜", text: "법전이 비어 있어요.")
                }
                ForEach(Array(store.data.laws.enumerated()), id: \.element.id) { index, law in
                    VStack(alignment: .leading, spacing: 3) {
                        Text("제\(index + 1)조 (\(law.title))")
                            .font(.system(size: 15, weight: .bold))
                        Text(law.text)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    .swipeActions {
                        Button(role: .destructive) {
                            store.deleteLaw(law.id)
                        } label: {
                            Label("없애기", systemImage: "trash")
                        }
                        Button {
                            editingLaw = law
                        } label: {
                            Label("고치기", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle("우리 집 법전")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) { LawFormView(law: nil) }
        .sheet(item: $editingLaw) { law in LawFormView(law: law) }
    }
}

struct LawFormView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    let law: Law?
    @State private var title = ""
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("법 이름") {
                    TextField("예: 존중, 정리정돈, 게임 시간", text: $title)
                }
                Section("내용") {
                    TextEditor(text: $text)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("예: 가족은 서로에게 나쁜 말을 하지 않는다.")
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
            .navigationTitle(law == nil ? "➕ 새로운 법 만들기" : "✏️ 법 고치기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(law == nil ? "법전에 올리기" : "저장") {
                        let t = title.trimmingCharacters(in: .whitespaces)
                        let x = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty, !x.isEmpty else { return }
                        if let law { store.updateLaw(law.id, title: t, text: x) }
                        else { store.addLaw(title: t, text: x) }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty ||
                              text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let law {
                    title = law.title
                    text = law.text
                }
            }
        }
    }
}

// MARK: - 가족

struct FamilyView: View {
    @EnvironmentObject var store: Store

    private static let emojis = ["👨","👩","👧","👦","👶","👴","👵","🧑","🦁","🐰","🐻","🐱","🐶","🦊","🐼","🦄"]

    @State private var name = ""
    @State private var pickedEmoji = "👨"

    var body: some View {
        List {
            Section(header: Text("우리 가족 등록부"),
                    footer: Text("재판에 참여할 가족을 모두 등록해 주세요. 누구든 사건에 따라 원고도, 검사도, 판사도 될 수 있어요!")) {
                if store.data.members.isEmpty {
                    EmptyNotice(emoji: "🪑", text: "아직 등록된 가족이 없어요.\n아래에서 가족을 추가해 주세요!")
                }
                ForEach(store.data.members) { m in
                    HStack(spacing: 12) {
                        Text(m.emoji).font(.system(size: 28))
                        Text(m.name).font(.system(size: 16, weight: .semibold))
                    }
                }
                .onDelete { offsets in
                    for i in offsets { store.deleteMember(store.data.members[i].id) }
                }
            }

            Section("가족 추가하기") {
                TextField("이름 (별명도 좋아요)", text: $name)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                    ForEach(Self.emojis, id: \.self) { e in
                        Button {
                            pickedEmoji = e
                        } label: {
                            Text(e)
                                .font(.system(size: 24))
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(pickedEmoji == e ? Color.blue.opacity(0.15) : Color(.tertiarySystemFill))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(pickedEmoji == e ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
                Button {
                    let n = name.trimmingCharacters(in: .whitespaces)
                    guard !n.isEmpty else { return }
                    store.addMember(name: n, emoji: pickedEmoji)
                    name = ""
                } label: {
                    Text("등록하기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("우리 가족")
    }
}

// MARK: - 설정

struct SettingsView: View {
    @EnvironmentObject var store: Store

    @State private var courtName = ""
    @State private var importing = false
    @State private var importMessage: String?

    var body: some View {
        Form {
            Section("법원 이름") {
                TextField("예: 김씨네 가정법원", text: $courtName)
                Button("이름 바꾸기") {
                    let n = courtName.trimmingCharacters(in: .whitespaces)
                    guard !n.isEmpty else { return }
                    store.data.courtName = n
                }
                .disabled(courtName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Section(header: Text("어휘 난이도"),
                    footer: Text(store.data.vocabLevel.caption)) {
                Picker("어휘 난이도", selection: Binding(
                    get: { store.data.vocabLevel },
                    set: { store.data.vocabLevel = $0 }
                )) {
                    ForEach(VocabLevel.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                VStack(alignment: .leading, spacing: 4) {
                    Text("미리보기")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(store.vocab.judge) · \(store.vocab.accuser(.civil)) · \(store.vocab.accused(.civil)) · \(store.vocab.accuser(.criminal)) · \(store.vocab.lawyer)")
                        .font(.system(size: 15, weight: .semibold))
                }
                .padding(.vertical, 2)
            }

            Section(header: Text("기록 보관소 (백업)"),
                    footer: Text("앱의 모든 기록(가족, 법전, 소송, 판결)을 파일로 저장해두거나 다시 불러올 수 있어요. 기기를 바꿀 때 사용하세요.")) {
                if let url = store.writeBackupFile() {
                    ShareLink(item: url) {
                        Label("기록 저장", systemImage: "square.and.arrow.up")
                    }
                }
                Button {
                    importing = true
                } label: {
                    Label("기록 불러오기", systemImage: "square.and.arrow.down")
                }
            }

            Section("우리 법원은 이렇게 움직여요") {
                Text("이 법원에는 정해진 대장(마스터)이 없어요.\n① 억울한 사람이 직접 소송을 접수하면서 → ② 누구를 고소할지, 누가 판사를 볼지 스스로 정해요.\n③ 접수하는 순간 소송이 시작되고 → ④ 재판을 열어 공정하게 해결해요.\n재판이 끝나면 꼭 서로 안아주고 화해해요. 🤗")
                    .font(.system(size: 15))
            }
        }
        .navigationTitle("설정")
        .onAppear { courtName = store.data.courtName }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                do {
                    try store.importBackup(from: url)
                    importMessage = "기록을 불러왔어요!"
                } catch {
                    importMessage = "파일을 읽을 수 없어요"
                }
            case .failure:
                importMessage = "파일을 읽을 수 없어요"
            }
        }
        .alert(importMessage ?? "", isPresented: Binding(
            get: { importMessage != nil },
            set: { if !$0 { importMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        }
    }
}

// MARK: - 법원 공부하기

struct LearnView: View {
    @EnvironmentObject var store: Store

    private var roles: [(String, String)] {
        let v = store.vocab
        return [
            ("👨‍⚖️ \(v.judge)", "양쪽 이야기를 끝까지 듣고 공정하게 정해요. 사건과 관련 없는 사람이 맡고, 재판을 신청하는 사람이 골라요."),
            ("🙋 \(v.accuser(.civil))", "억울한 일을 겪어서 재판을 신청한 사람이에요. \(v.typeName(.civil)) 재판에서 이야기를 시작해요."),
            ("🕵️ \(v.accuser(.criminal))", "우리 집 법을 어긴 일을 밝히는 사람이에요. \(v.typeName(.criminal)) 재판을 열고 벌칙을 정해 달라고 해요. 부모님도 될 수 있어요!"),
            ("🙇 \(v.accused(.civil))", "재판에 불려 나온 사람이에요. 자기 생각을 이야기할 권리가 있고, \(v.eul(v.lawyer)) 고를 수 있어요."),
            ("🛡️ \(v.lawyer)", "재판에 불려 나온 사람 편에서 도와줘요. 지켜 주는 좋은 이유를 찾아 줘요."),
            ("✍️ \(v.clerk)", "재판에서 나온 이야기를 기록하는 사람이에요. 없어도 재판은 열 수 있어요.")
        ]
    }

    private var civilSteps: [String] {
        let v = store.vocab
        return [
            "\(v.ga(v.judge)) 재판 시작을 알려요 (\(v.openingTitle)) 🔨",
            "사건을 소개해요",
            "\(v.ga(v.accuser(.civil))) 억울한 이야기를 해요",
            "\(v.ga(v.accused(.civil))) 자기 이야기를 해요",
            "서로 묻고 답해요",
            "\(v.ga(v.lawyer)) 도와줘요",
            "마지막 한마디씩 해요 (\(v.lastWordTitle))",
            "\(v.ga(v.judge)) 정해요: \(v.verdictBadge("원고 승소")) · \(v.verdictBadge("피고 승소")) · \(v.verdictBadge("화해 권고"))"
        ]
    }

    private var criminalSteps: [String] {
        let v = store.vocab
        return [
            "\(v.ga(v.judge)) 재판 시작을 알려요 🔨",
            "\(v.ga(v.accuser(.criminal))) 어긴 법을 읽어요 (\(v.indictmentTitle))",
            "\(v.ga(v.accused(.criminal))) 자기 이야기를 해요",
            "\(v.ga(v.accuser(.criminal))) 질문해요",
            "\(v.ga(v.lawyer)) 도와줘요",
            "\(v.ga(v.accuser(.criminal))) 바라는 벌칙을 말해요 (\(v.demandTitle))",
            "\(v.lastWordTitle)를 해요",
            "\(v.ga(v.judge)) 정해요: \(v.verdictBadge("유죄")) · \(v.verdictBadge("무죄")) · \(v.verdictBadge("선처"))"
        ]
    }

    private let manners = [
        "다른 사람 이야기는 끝까지 들어요",
        "소리 지르지 않아요",
        "사실만 말해요",
        "판결이 나면 승복해요",
        "재판이 끝나면 꼭 안아주고 화해해요 🤗"
    ]

    var body: some View {
        List {
            Section("🎭 누가 무엇을 하나요?") {
                ForEach(roles, id: \.0) { role, description in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(role).font(.system(size: 15, weight: .bold))
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            stepsSection(title: "⚖️ 민사 재판은 이렇게 진행돼요",
                         footer: "억울한 일을 해결하고 사과나 보상을 받는 재판이에요.",
                         steps: civilSteps)
            stepsSection(title: "🚨 형사 재판은 이렇게 진행돼요",
                         footer: "우리 집 법을 어긴 사람의 벌칙을 정하는 재판이에요.",
                         steps: criminalSteps)
            stepsSection(title: "🤝 재판 약속 5가지", footer: nil, steps: manners)
        }
        .navigationTitle("법원 공부하기")
    }

    private func stepsSection(title: String, footer: String?, steps: [String]) -> some View {
        Section(header: Text(title), footer: footer.map { Text($0) }) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.blue)
                        .clipShape(Circle())
                    Text(step).font(.system(size: 15))
                }
                .padding(.vertical, 1)
            }
        }
    }
}
