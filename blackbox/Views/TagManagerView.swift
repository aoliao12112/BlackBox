//
//  TagManagerView.swift
//  blackbox
//
//  Week 5 · 标签管理页 + 标签筛选页
//  Spec: spec.md P9 标签管理
//

import SwiftUI

// MARK: - 标签管理页

struct TagManagerView: View {

    @EnvironmentObject private var router: Router
    private let repository: ContactRepositoryProtocol = FileManagerContactRepository.shared

    @State private var tags: [(name: String, count: Int)] = []
    @State private var tagToDelete: String?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if tags.isEmpty {
                ContentUnavailableView(
                    "还没有标签",
                    systemImage: "tag",
                    description: Text("在名片详情页点「添加标签」即可创建")
                )
            } else {
                List {
                    ForEach(tags, id: \.name) { item in
                        HStack {
                            Text("#\(item.name)")
                            Spacer()
                            Text("\(item.count)")
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            router.navigate(to: .tagFilter(tagName: item.name))
                        }
                    }
                    .onDelete { indexSet in
                        if let idx = indexSet.first {
                            tagToDelete = tags[idx].name
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("标签")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            Text("删除标签「\(tagToDelete ?? "")」？"),
            isPresented: .init(
                get: { tagToDelete != nil },
                set: { if !$0 { tagToDelete = nil } }
            ),
            titleVisibility: .visible,
            actions: {
                Button("删除", role: .destructive) {
                    if let name = tagToDelete {
                        Task { await deleteTag(name) }
                    }
                    tagToDelete = nil
                }
                Button("取消", role: .cancel) { tagToDelete = nil }
            },
            message: {
                Text("将从所有名片中移除该标签")
            }
        )
        .alert("操作失败", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task { await reload() }
    }

    private func reload() async {
        do {
            let cards = try await repository.fetchAllCards()
            var counts: [String: Int] = [:]
            for card in cards {
                for tag in card.tags { counts[tag.name, default: 0] += 1 }
            }
            tags = counts.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        } catch {
            errorMessage = "读取标签失败：\(error.localizedDescription)"
        }
    }

    private func deleteTag(_ name: String) async {
        do {
            let cards = try await repository.fetchAllCards()
            for var card in cards {
                let before = card.tags.count
                card.tags.removeAll { $0.name == name }
                if card.tags.count != before {
                    try await repository.save(card)
                }
            }
            await reload()
        } catch {
            errorMessage = "删除标签失败：\(error.localizedDescription)"
        }
    }
}

// MARK: - 标签筛选页

struct TagFilterView: View {

    @EnvironmentObject private var router: Router
    let tagName: String
    private let repository: ContactRepositoryProtocol = FileManagerContactRepository.shared

    @State private var cards: [BusinessCard] = []

    var body: some View {
        Group {
            if cards.isEmpty {
                ContentUnavailableView(
                    "没有带此标签的名片",
                    systemImage: "tag",
                    description: Text("#\(tagName)")
                )
            } else {
                List(cards) { card in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Text(String(card.name?.prefix(1) ?? "?"))
                                    .font(.headline)
                                    .foregroundColor(Color.accentColor)
                            }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.name ?? "(未命名)").font(.headline)
                            Text(card.company ?? "").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        router.navigate(to: .cardDetail(cardID: card.id))
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("#\(tagName)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await reload() }
        .onAppear {
            Task { await reload() }
        }
    }

    private func reload() async {
        cards = (try? await repository.filterByTag(tagName)) ?? []
    }
}

#Preview {
    NavigationStack {
        TagManagerView()
    }
    .environmentObject(Router())
}
