//
//  MockContactRepository.swift
//  blackbox
//
//  Created by admin on 2026/10/13.
//
//  Week 1 骨架：Mock 实现，用于 UI 预览 & 测试
//  Week 5 替换为真实 FileManager + JSON 实现
//

import Foundation

/// 内存中的 Mock 仓库 —— Week 2/5 替换为真实持久化
final class MockContactRepository: ContactRepositoryProtocol {
    
    static let sampleCards: [BusinessCard] = [
        BusinessCard.makeSample(name: "王小明", company: "上海智联科技", mobile: "+86 138-0000-0001"),
        BusinessCard.makeSample(name: "David Chen", company: "ABC Technologies", mobile: "+1-555-123-4567"),
        BusinessCard.makeSample(name: "李华", company: "同济大学", mobile: "+86 139-0000-0002"),
    ]
    
    private var store: [BusinessCard] = []
    
    init() {
        self.store = Self.sampleCards
    }
    
    // MARK: - ContactRepositoryProtocol
    
    func fetchAllCards() async throws -> [BusinessCard] { store }
    func fetchCard(id: UUID) async throws -> BusinessCard? { store.first { $0.id == id } }
    func save(_ card: BusinessCard) async throws {
        if let idx = store.firstIndex(where: { $0.id == card.id }) {
            store[idx] = card
        } else {
            store.insert(card, at: 0)
        }
    }
    func delete(id: UUID) async throws {
        store.removeAll { $0.id == id }
    }
    func deleteMultiple(ids: [UUID]) async throws {
        store.removeAll { ids.contains($0.id) }
    }
    func search(keyword: String) async throws -> [BusinessCard] {
        store.filter { $0.matches(keyword) }
    }
    func filterByTag(_ tagName: String) async throws -> [BusinessCard] {
        store.filter { $0.tags.contains(where: { $0.name == tagName }) }
    }
}

// MARK: - BusinessCard 样本工厂（Preview 用）

extension BusinessCard {
    static func makeSample(
        name: String,
        company: String,
        mobile: String,
        jobTitle: String? = nil,
        email: String? = nil,
        website: String? = nil,
        address: String? = nil
    ) -> BusinessCard {
        BusinessCard(
            id: UUID(),
            originalImageData: nil,
            processedImageData: nil,
            name: name,
            company: company,
            jobTitle: jobTitle,
            department: nil,
            mobile: mobile,
            officePhone: nil,
            fax: nil,
            email: email,
            website: website,
            address: address,
            postalCode: nil,
            tags: [],
            notes: nil,
            createdAt: Date(),
            updatedAt: nil,
            ocrRawText: nil,
            fieldConfidence: nil
        )
    }
}
