//
//  CardDetailView.swift
//  blackbox
//
//  Week 2 · 名片详情页骨架 — Week 5 完善持久化后接真实数据
//  Spec: spec.md P6 名片详情页
//

import SwiftUI
import UIKit

struct CardDetailView: View {
    
    @EnvironmentObject private var router: Router
    let cardID: UUID
    
    @State private var card: BusinessCard?
    @State private var showDeleteConfirm = false
    @State private var showAddTag = false
    @State private var newTagName = ""
    @State private var operationError: String?
    
    private let repository: ContactRepositoryProtocol = FileManagerContactRepository.shared
    
    var body: some View {
        Group {
            if let card {
                cardList(card)
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
                    Button {
                        if let card { router.navigate(to: .export(card: card)) }
                    } label: { Label("导出", systemImage: "square.and.arrow.up") }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: { Label("删除", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            Text("删除这张名片？"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                Task {
                    do {
                        try await repository.delete(id: cardID)
                        router.pop()
                    } catch {
                        operationError = "删除失败：\(error.localizedDescription)"
                    }
                }
            }
            Button("取消", role: .cancel) {}
        }
        .alert("添加标签", isPresented: $showAddTag) {
            TextField("标签名称", text: $newTagName)
            Button("添加") { Task { await addTag() } }
            Button("取消", role: .cancel) {}
        }
        .alert("操作失败", isPresented: Binding(
            get: { operationError != nil },
            set: { if !$0 { operationError = nil } }
        )) {
            Button("好", role: .cancel) { operationError = nil }
        } message: {
            Text(operationError ?? "")
        }
        .task(id: cardID) {
            await reloadCard()
        }
        .onAppear {
            // 从编辑页 pop 回来时重新加载最新数据
            Task {
                await reloadCard()
            }
        }
    }
    
    // MARK: - Private Views (拆小以避免编译器超时)
    
    @ViewBuilder
    private func cardList(_ card: BusinessCard) -> some View {
        List {
            imagesSection(card)
            headerSection(card)
            contactSection(card)
            tagsSection(card)
            notesSection(card)
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private func headerSection(_ card: BusinessCard) -> some View {
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
                if let department = card.department {
                    Text(department)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private func contactSection(_ card: BusinessCard) -> some View {
        Section(header: Text("联系方式")) {
            if let mobile = card.mobile {
                ContactRow(label: "手机", value: mobile, url: makeURL(scheme: "tel", value: mobile))
            }
            if let phone = card.officePhone {
                ContactRow(label: "办公电话", value: phone, url: makeURL(scheme: "tel", value: phone))
            }
            if let fax = card.fax {
                ContactRow(label: "传真", value: fax, url: makeURL(scheme: "tel", value: fax))
            }
            if let email = card.email {
                ContactRow(label: "Email", value: email, url: makeURL(scheme: "mailto", value: email))
            }
            ForEach(Array((card.additionalEmails ?? []).enumerated()), id: \.offset) { item in
                ContactRow(label: "其他 Email", value: item.element,
                           url: makeURL(scheme: "mailto", value: item.element))
            }
            if let website = card.website {
                ContactRow(label: "网址", value: website, url: websiteURL(website))
            }
            if let address = card.address {
                ContactRow(label: "地址", value: address, url: nil)
            }
            if let postalCode = card.postalCode {
                ContactRow(label: "邮编", value: postalCode, url: nil)
            }
        }
    }
    
    @ViewBuilder
    private func tagsSection(_ card: BusinessCard) -> some View {
        Section(header: Text("标签")) {
            if !card.tags.isEmpty {
                HStack(spacing: 8) {
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
                .padding(.vertical, 2)
            }
            Button {
                newTagName = ""
                showAddTag = true
            } label: {
                Label("添加标签", systemImage: "plus.circle")
            }
        }
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func imagesSection(_ card: BusinessCard) -> some View {
        let original = card.originalImageData.flatMap { UIImage(data: $0) }
        let processed = card.processedImageData.flatMap { UIImage(data: $0) }
        if original != nil || processed != nil {
            Section(header: Text("图片")) {
                HStack(spacing: 12) {
                    if let original { labeledImage(original, caption: "原图") }
                    if let processed { labeledImage(processed, caption: "校正图") }
                }
            }
        }
    }

    @ViewBuilder
    private func labeledImage(_ image: UIImage, caption: String) -> some View {
        VStack(spacing: 4) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private func addTag() async {
        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, var current = card else { return }
        if !current.tags.contains(where: { $0.name == name }) {
            // 复用已有同名标签的 id，保证跨名片共享同一 Tag
            do {
                let existingID = try await repository.fetchAllCards()
                    .flatMap { $0.tags }
                    .first(where: { $0.name == name })?.id
                current.tags.append(Tag(id: existingID ?? UUID(), name: name, colorHex: nil))
                try await repository.save(current)
                card = current
            } catch {
                operationError = "保存标签失败：\(error.localizedDescription)"
            }
        }
    }

    private func reloadCard() async {
        do {
            card = try await repository.fetchCard(id: cardID)
            if card == nil { operationError = "未找到这张名片" }
        } catch {
            operationError = "读取名片失败：\(error.localizedDescription)"
        }
    }
    
    @ViewBuilder
    private func notesSection(_ card: BusinessCard) -> some View {
        if let notes = card.notes, !notes.isEmpty {
            Section(header: Text("备注")) {
                Text(notes)
                    .font(.body)
            }
        }
    }
    
    private func makeURL(scheme: String, value: String) -> URL? {
        guard let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: "\(scheme):\(encoded)")
    }

    private func websiteURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        return URL(string: "https://\(trimmed)")
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
