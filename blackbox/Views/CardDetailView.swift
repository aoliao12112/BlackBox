//
//  CardDetailView.swift
//  blackbox
//
//  Week 2 · 名片详情页骨架 — Week 5 完善持久化后接真实数据
//  Spec: spec.md P6 名片详情页
//

import SwiftUI

struct CardDetailView: View {
    
    @EnvironmentObject private var router: Router
    let cardID: UUID
    
    @State private var card: BusinessCard?
    @State private var showDeleteConfirm = false
    
    private let repository: ContactRepositoryProtocol = MockContactRepository()
    
    var body: some View {
        Group {
            if let card {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(card.name ?? "(未命名)")
                                .font(.title2.bold())
                            if let company = card.company {
                                Text(company)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            if let jobTitle = card.jobTitle {
                                Text(jobTitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Section(header: Text("联系方式")) {
                        if let mobile = card.mobile {
                            ContactRow(label: "手机", value: mobile, url: URL(string: "tel:\(mobile.filter { $0.isNumber || $0 == "+" })"))
                        }
                        if let phone = card.officePhone {
                            ContactRow(label: "办公电话", value: phone, url: URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })"))
                        }
                        if let email = card.email {
                            ContactRow(label: "Email", value: email, url: URL(string: "mailto:\(email)"))
                        }
                        if let website = card.website {
                            ContactRow(label: "网址", value: website, url: URL(string: "https://\(website)"))
                        }
                        if let address = card.address {
                            ContactRow(label: "地址", value: address, url: nil)
                        }
                    }
                    
                    if !card.tags.isEmpty {
                        Section(header: Text("标签")) {
                            FlowLayout(spacing: 6) {
                                ForEach(card.tags) { tag in
                                    Text(tag.name)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.15))
                                        .foregroundColor(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("名片详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        if let card { router.navigate(to: .cardEdit(card: card)) }
                    } label: { Label("编辑", systemImage: "pencil") }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: { Label("删除", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("删除这张名片？", isPresented: $showDeleteConfirm, role: .destructive, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                Task {
                    try? await repository.delete(id: cardID)
                    router.pop()
                }
            }
            Button("取消", role: .cancel) {}
        }
        .task {
            card = try? await repository.fetchCard(id: cardID)
        }
    }
}

/// 详情页里联系字段的一行
private struct ContactRow: View {
    let label: String
    let value: String
    let url: URL?
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            
            if let url {
                Link(value, destination: url)
                    .foregroundColor(Color.accentColor)
            } else {
                Text(value)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CardDetailView(cardID: MockContactRepository.sampleCards[0].id)
    }
    .environmentObject(Router())
}
