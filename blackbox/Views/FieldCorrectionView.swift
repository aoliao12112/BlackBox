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
    
    let repository: ContactRepositoryProtocol = MockContactRepository()
    
    init(card: BusinessCard) {
        _card = State(initialValue: card)
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                FieldRow(label: "姓名", text: Binding(
                    get: { card.name ?? "" },
                    set: { card.name = $0.isEmpty ? nil : $0 }
                ))
                FieldRow(label: "公司", text: Binding(
                    get: { card.company ?? "" },
                    set: { card.company = $0.isEmpty ? nil : $0 }
                ))
                FieldRow(label: "职位", text: Binding(
                    get: { card.jobTitle ?? "" },
                    set: { card.jobTitle = $0.isEmpty ? nil : $0 }
                ))
            }
            
            Section(header: Text("联系方式")) {
                FieldRow(label: "手机", text: Binding(
                    get: { card.mobile ?? "" },
                    set: { card.mobile = $0.isEmpty ? nil : $0 }
                ))
                FieldRow(label: "办公电话", text: Binding(
                    get: { card.officePhone ?? "" },
                    set: { card.officePhone = $0.isEmpty ? nil : $0 }
                ))
                FieldRow(label: "Email", text: Binding(
                    get: { card.email ?? "" },
                    set: { card.email = $0.isEmpty ? nil : $0 }
                ))
                FieldRow(label: "网址", text: Binding(
                    get: { card.website ?? "" },
                    set: { card.website = $0.isEmpty ? nil : $0 }
                ))
                FieldRow(label: "地址", text: Binding(
                    get: { card.address ?? "" },
                    set: { card.address = $0.isEmpty ? nil : $0 }
                ))
            }
            
            Section {
                Button {
                    Task {
                        card.updatedAt = Date()
                        try? await repository.save(card)
                        router.popToRoot()
                    }
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
