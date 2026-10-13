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

    @Published var errorMessage: String?
    
    // MARK: - 依赖
    
    private let repository: ContactRepositoryProtocol
    
    // MARK: - Init
    
    init(repository: ContactRepositoryProtocol = FileManagerContactRepository.shared) {
        self.repository = repository
    }
    
    // MARK: - 数据加载
    
    func loadCards() async {
        do {
            cards = try await repository.fetchAllCards()
            errorMessage = nil
        } catch {
            cards = []
            errorMessage = "读取名片失败：\(error.localizedDescription)"
        }
    }
    
    // MARK: - 搜索（Week 5 实现）
    
    func performSearch() async {
        // Week 5 TODO: repository.search(keyword:)
    }
    
    // MARK: - 删除（Week 5 实现）
    
    func deleteCard(id: UUID) async {
        do {
            try await repository.delete(id: id)
            cards = try await repository.fetchAllCards()
        } catch {
            errorMessage = "删除失败：\(error.localizedDescription)"
        }
    }
}
