//
//  HomeView.swift
//  blackbox
//
//  Created by admin on 2026/10/13.
//
//  Week 1 骨架 — Week 2 实现完整 UI
//  Spec: spec.md §1 P1 名片夹首页
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.cards.isEmpty {
                    // T01 空状态
                    EmptyStateView(onScan: startScanning)
                } else {
                    // 名片列表
                    List {
                        ForEach(viewModel.cards) { card in
                            CardRowView(card: card)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // Week 2 TODO: 跳转到 CardDetailView
                                }
                        }
                        .onDelete { indexSet in
                            // Week 2 TODO: 删除确认弹窗 + 调用 viewModel.deleteCard
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("名片夹")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: startScanning) {
                        Image(systemName: "camera.viewfinder")
                    }
                }
            }
        }
        .task {
            await viewModel.loadCards()
        }
    }
    
    private func startScanning() {
        // Week 2 TODO: Navigate to ScannerView
        // 当前仅做占位
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
                .foregroundStyle(.primary)
            
            Text("扫描一张名片，开始建立你的名片夹")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button(action: onScan) {
                Label("扫描名片", systemImage: "camera.viewfinder")
                    .font(.headline)
                    .frame(minWidth: 140)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
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
            // 头像/首字母
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                Text(String(card.name?.prefix(1) ?? "?"))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.accentColor)
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
    HomeView()
}
