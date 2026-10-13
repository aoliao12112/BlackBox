//
//  FieldCorrectionView.swift
//  blackbox
//
//  Week 2 · 字段校正页骨架 — Week 4 接字段抽取 + 置信度
//  Spec: spec.md P5 字段校正页
//

import SwiftUI

struct FieldCorrectionView: View {
    
    @EnvironmentObject private var router: Router
    @State private var card: BusinessCard
    @State private var initialCard: BusinessCard?
    @State private var saveError: String?
    
    /// 保存后导航方式：新建名片回首页 / 编辑名片回上一层
    enum SaveDestination { case home, pop }
    private let saveDestination: SaveDestination
    
    let repository: ContactRepositoryProtocol = FileManagerContactRepository.shared
    
    init(card: BusinessCard, saveDestination: SaveDestination = .home) {
        _card = State(initialValue: card)
        self.saveDestination = saveDestination
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                FieldRow(label: "姓名", text: binding(\.name))
                FieldRow(label: "公司", text: binding(\.company))
                FieldRow(label: "职位", text: binding(\.jobTitle))
                FieldRow(label: "部门", text: binding(\.department))
            }
            
            Section(header: Text("联系方式")) {
                FieldRow(label: "手机", text: binding(\.mobile))
                FieldRow(label: "办公电话", text: binding(\.officePhone))
                FieldRow(label: "传真", text: binding(\.fax))
                FieldRow(label: "Email", text: binding(\.email))
                FieldRow(label: "其他 Email", text: additionalEmailsBinding)
                FieldRow(label: "网址", text: binding(\.website))
                FieldRow(label: "地址", text: binding(\.address))
                FieldRow(label: "邮编", text: binding(\.postalCode))
            }
            
            Section(header: Text("备注")) {
                TextEditor(text: binding(\.notes))
                    .frame(minHeight: 80)
            }
            
            Section {
                Button {
                    save()
                } label: {
                    HStack {
                        Spacer()
                        Label("保存名片", systemImage: "checkmark.circle.fill")
                            .foregroundColor(Color.accentColor)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("确认名片")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { router.pop() }
            }
        }
        .alert("保存失败", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("好", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
        .onAppear {
            if initialCard == nil { initialCard = card }
        }
    }
    
    /// 保存：标记手工修改字段为 .manual 来源，再落盘；失败时提示用户（E7）
    private func save() {
        markManualEdits()
        card.updatedAt = Date()
        Task {
            do {
                try await repository.save(card)
                switch saveDestination {
                case .home: router.popToRoot()
                case .pop:  router.pop()
                }
            } catch {
                saveError = "未能写入名片：\(error.localizedDescription)"
            }
        }
    }
    
    /// 遍历所有可编辑字段，较初始值发生变化的字段标记为「人工修正」（source = .manual），对应 T11
    private func markManualEdits() {
        guard let initial = initialCard else { return }
        var conf = card.fieldConfidence ?? []
        let fields: [(String, WritableKeyPath<BusinessCard, String?>)] = [
            ("name", \.name), ("company", \.company), ("jobTitle", \.jobTitle),
            ("department", \.department), ("mobile", \.mobile), ("officePhone", \.officePhone),
            ("fax", \.fax), ("email", \.email), ("website", \.website),
            ("address", \.address), ("postalCode", \.postalCode), ("notes", \.notes)
        ]
        for (key, keyPath) in fields where card[keyPath: keyPath] != initial[keyPath: keyPath] {
            let raw = card[keyPath: keyPath] ?? ""
            let entry = FieldConfidence(fieldName: key, rawValue: raw, confidence: 1.0, source: .manual)
            if let idx = conf.firstIndex(where: { $0.fieldName == key }) {
                conf[idx] = entry
            } else {
                conf.append(entry)
            }
        }
        if card.additionalEmails != initial.additionalEmails {
            let value = (card.additionalEmails ?? []).joined(separator: ", ")
            let entry = FieldConfidence(fieldName: "additionalEmails", rawValue: value,
                                        confidence: 1.0, source: .manual)
            if let idx = conf.firstIndex(where: { $0.fieldName == "additionalEmails" }) {
                conf[idx] = entry
            } else {
                conf.append(entry)
            }
        }
        card.fieldConfidence = conf
    }
    
    /// 将某个可选字符串字段包装成可读写 Binding（空串 ↔ nil）
    private func binding(_ keyPath: WritableKeyPath<BusinessCard, String?>) -> Binding<String> {
        Binding(
            get: { self.card[keyPath: keyPath] ?? "" },
            set: { self.card[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }

    private var additionalEmailsBinding: Binding<String> {
        Binding(
            get: { (card.additionalEmails ?? []).joined(separator: ", ") },
            set: { value in
                let values = value.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                card.additionalEmails = values.isEmpty ? nil : values
            }
        )
    }
}

/// 表单里单个标签 + 输入框
struct FieldRow: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            TextField("未识别", text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    NavigationStack {
        FieldCorrectionView(card: .makeSample(
            name: "王小明",
            company: "上海智联科技",
            mobile: "+86 138-0000-0001",
            jobTitle: "研发总监",
            email: "wangxm@zhilian.example.cn"
        ))
    }
}
