//
//  SearchView.swift
//  blackbox
//
//  Week 2 · 搜索页骨架 — Week 5 接真实搜索
//  Spec: spec.md P8 搜索
//

import SwiftUI

struct SearchView: View {
    
    @EnvironmentObject private var router: Router
    @State private var keyword = ""
    @State private var results: [BusinessCard] = []
    
    private let repository: ContactRepositoryProtocol = MockContactRepository()
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索姓名、公司、电话、Email…", text: $keyword)
                    .textInputAutocapitalization(.never)
                if !keyword.isEmpty {
                    Button { keyword = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()
            
            Divider()
            
            // 结果
            Group {
                if results.isEmpty && keyword.isEmpty {
                    Spacer()
                    Text("开始输入以搜索")
                        .foregroundStyle(.tertiary)
                    Spacer()
                } else if results.isEmpty {
                    Spacer()
                    Text("未找到匹配的名片")
                        .foregroundStyle(.tertiary)
                    Spacer()
                } else {
                    List(results) { card in
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
        }
        .navigationTitle("搜索")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: keyword) {
            // Week 5 TODO: 调 repository.search(keyword:)
            try? await Task.sleep(nanoseconds: 200_000_000)
            results = (try? await repository.search(keyword: keyword)) ?? []
        }
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .environmentObject(Router())
}
