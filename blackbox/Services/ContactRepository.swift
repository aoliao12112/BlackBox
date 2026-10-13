//
//  ContactRepository.swift
//  blackbox
//
//  Created by admin on 2026/10/13.
//
//  Week 1 骨架：Repository Protocol 定义，Week 2/5 实现
//

import Foundation

// MARK: - 名片仓库协议

/// BusinessCard 数据持久化接口
/// Week 5 实现本地存储（FileManager + JSON）
protocol ContactRepositoryProtocol {
    
    // MARK: - CRUD
    
    /// 获取所有名片（按创建时间倒序）
    func fetchAllCards() async throws -> [BusinessCard]
    
    /// 获取单张名片
    func fetchCard(id: UUID) async throws -> BusinessCard?
    
    /// 保存名片（新建或更新）
    func save(_ card: BusinessCard) async throws
    
    /// 删除名片
    func delete(id: UUID) async throws
    
    /// 批量删除
    func deleteMultiple(ids: [UUID]) async throws
    
    // MARK: - 搜索 & 筛选
    
    /// 关键词搜索（匹配 name / company / jobTitle / mobile / email）
    func search(keyword: String) async throws -> [BusinessCard]
    
    /// 按标签筛选
    func filterByTag(_ tagName: String) async throws -> [BusinessCard]
}

// MARK: - 标签仓库协议

/// Tag 管理接口
/// Week 5 实现
protocol TagRepositoryProtocol {
    
    func fetchAllTags() async throws -> [Tag]
    func save(_ tag: Tag) async throws
    func delete(id: UUID) async throws
}
