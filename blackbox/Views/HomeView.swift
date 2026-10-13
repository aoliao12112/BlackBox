//
//  HomeView.swift
//  blackbox
//
//  Week 2 · 名片夹首页（可导航版本）
//  Spec: spec.md §1 P1 名片夹首页
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = HomeViewModel()
    @State private var cardToDelete: BusinessCard?
    
    var body: some View {
        Group {
            if viewModel.cards.isEmpty {
                EmptyStateView(onScan: { router.navigate(to: .scanner) })
            } else {
                List {
                    ForEach(viewModel.cards) { card in
                        CardRowView(card: card)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                router.navigate(to: .cardDetail(cardID: card.id))
                            }
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            cardToDelete = viewModel.cards[index]
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("名片夹")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { router.navigate(to: .search) } label: {
                    Image(systemName: "magnifyingglass")
                }
                Button { router.navigate(to: .tagManager) } label: {
                    Image(systemName: "tag")
                }
                Button { router.navigate(to: .scanner) } label: {
                    Image(systemName: "camera.viewfinder")
                }
            }
        }
        .confirmationDialog(
            Text("删除这张名片？"),
            isPresented: .init(
                get: { cardToDelete != nil },
                set: { if !$0 { cardToDelete = nil } }
            ),
            titleVisibility: .visible,
            actions: {
                Button("删除", role: .destructive) {
                    if let card = cardToDelete {
                        Task { await viewModel.deleteCard(id: card.id) }
                    }
                    cardToDelete = nil
                }
                Button("取消", role: .cancel) { cardToDelete = nil }
            }
        )
        .alert("操作失败", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("好", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task { await viewModel.loadCards() }
    }
}

// MARK: - 空状态

private struct EmptyStateView: View {
    let onScan: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 70))
                .foregroundStyle(.tertiary)
            
            Text("还没有名片")
                .font(.title2)
            
            Text("扫描一张名片，开始建立你的名片夹")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button(action: onScan) {
                Label("扫描名片", systemImage: "camera.viewfinder")
                    .font(.headline)
                    .frame(minWidth: 140)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

// MARK: - 名片行

private struct CardRowView: View {
    let card: BusinessCard
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                Text(String(card.name?.prefix(1) ?? "?"))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.accentColor)
            }
            .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name ?? "(未命名)")
                    .font(.headline)
                Text(card.company ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let jobTitle = card.jobTitle {
                    Text(jobTitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(Router())
}
