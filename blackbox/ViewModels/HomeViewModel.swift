//
//  HomeViewModel.swift
//  blackbox
//
//  Created by admin on 2026/10/13.
//
//  Week 1 骨架 — Week 2 实现完整功能
//  Spec: spec.md P1 名片夹首页
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - 状态
    
    /// 名片列表（空 = 首次启动空状态）
    @Published private(set) var cards: [BusinessCard] = []
    
    /// 是否正在加载
    @Published private(set) var isLoading = false
    
    /// 当前搜索关键词
    @Published var searchKeyword: String = ""
    
    // MARK: - 依赖
    
    private let repository: ContactRepositoryProtocol
    
    // MARK: - Init
    
    init(repository: ContactRepositoryProtocol? = nil) {
        self.repository = repository ?? MockContactRepository()
    }
    
    // MARK: - 数据加载（Week 2 实现）
    
    func loadCards() async {
        // Week 2 TODO: 从 repository.fetchAllCards() 加载
        // 目前用 Mock 数据占位
        cards = MockContactRepository.sampleCards
    }
    
    // MARK: - 搜索（Week 5 实现）
    
    func performSearch() async {
        // Week 5 TODO: repository.search(keyword:)
    }
    
    // MARK: - 删除（Week 5 实现）
    
    func deleteCard(id: UUID) async {
        // Week 5 TODO: repository.delete(id:)
        cards.removeAll { $0.id == id }
    }
}
