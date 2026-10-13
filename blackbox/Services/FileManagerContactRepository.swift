//
//  FileManagerContactRepository.swift
//  blackbox
//
//  Week 2 · 真实持久化 — Documents/business_cards/
//  Spec: spec.md §4.3 持久化层
//

import Foundation
import UIKit

/// DocumentDirectory 中名片列表索引
private struct CardIndex: Codable {
    var entries: [Entry]
    
    struct Entry: Codable {
        let id: UUID
        let updatedAt: Date
    }
}

/// FileManager + JSON 持久化 ContactRepository 实现
final class FileManagerContactRepository: ContactRepositoryProtocol {
    
    /// 全局共享实例（生产环境真实持久化）
    static let shared = FileManagerContactRepository()

    private let baseDirectory: URL?
    
    // MARK: - Paths
    
    private var cardsDirectory: URL {
        if let baseDirectory { return baseDirectory }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("business_cards", isDirectory: true)
    }
    
    private var indexFileURL: URL {
        cardsDirectory.appendingPathComponent("index.json")
    }
    
    private func cardDirectory(for id: UUID) -> URL {
        cardsDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
    }
    
    // MARK: - Init
    
    /// 测试可传入隔离目录；生产环境默认使用 Documents/business_cards。
    init(baseDirectory: URL? = nil) {
        self.baseDirectory = baseDirectory
        try? ensureDirectoryExists(cardsDirectory)
    }
    
    // MARK: - ContactRepositoryProtocol
    
    func fetchAllCards() async throws -> [BusinessCard] {
        guard FileManager.default.fileExists(atPath: indexFileURL.path) else { return [] }
        let data = try Data(contentsOf: indexFileURL)
        let index = try Self.makeDecoder().decode(CardIndex.self, from: data)
        var cards: [BusinessCard] = []
        for entry in index.entries {
            if let card = try await fetchCard(id: entry.id) {
                cards.append(card)
            }
        }
        // 协议约定：按创建时间倒序
        return cards.sorted { $0.createdAt > $1.createdAt }
    }
    
    func fetchCard(id: UUID) async throws -> BusinessCard? {
        let dir = cardDirectory(for: id)
        let metaURL = dir.appendingPathComponent("meta.json")
        guard FileManager.default.fileExists(atPath: metaURL.path) else { return nil }
        let data = try Data(contentsOf: metaURL)
        var card = try Self.makeDecoder().decode(BusinessCard.self, from: data)
        
        let originalURL = dir.appendingPathComponent("original.jpg")
        let processedURL = dir.appendingPathComponent("processed.jpg")
        if FileManager.default.fileExists(atPath: originalURL.path) {
            card.originalImageData = try Data(contentsOf: originalURL)
        }
        if FileManager.default.fileExists(atPath: processedURL.path) {
            card.processedImageData = try Data(contentsOf: processedURL)
        }
        return card
    }
    
    func save(_ card: BusinessCard) async throws {
        let dir = cardDirectory(for: card.id)
        try ensureDirectoryExists(dir)
        
        // 存 meta.json
        var cardToSave = card
        cardToSave.updatedAt = Date()
        cardToSave.originalImageData = nil   // 图片单独存
        cardToSave.processedImageData = nil
        
        let metaData = try Self.makeEncoder().encode(cardToSave)
        try metaData.write(to: dir.appendingPathComponent("meta.json"))
        
        // 存图片（压缩至最长边 1024px / JPEG 0.7，见 spec §4.2）
        if let original = card.originalImageData {
            let data = UIImage(data: original).flatMap { ImageCompressor.compress($0) } ?? original
            try data.write(to: dir.appendingPathComponent("original.jpg"))
        }
        if let processed = card.processedImageData {
            let data = UIImage(data: processed).flatMap { ImageCompressor.compress($0) } ?? processed
            try data.write(to: dir.appendingPathComponent("processed.jpg"))
        }
        
        // 更新 index
        try updateIndex(with: card.id, updatedAt: cardToSave.updatedAt!)
    }
    
    func delete(id: UUID) async throws {
        let dir = cardDirectory(for: id)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
        
        // 更新 index
        if FileManager.default.fileExists(atPath: indexFileURL.path) {
            let data = try Data(contentsOf: indexFileURL)
            var index = try Self.makeDecoder().decode(CardIndex.self, from: data)
            index.entries.removeAll { $0.id == id }
            try Self.makeEncoder().encode(index).write(to: indexFileURL)
        }
    }
    
    func deleteMultiple(ids: [UUID]) async throws {
        for id in ids { try await delete(id: id) }
    }
    
    func search(keyword: String) async throws -> [BusinessCard] {
        let all = try await fetchAllCards()
        return all.filter { $0.matches(keyword) }
    }
    
    func filterByTag(_ tagName: String) async throws -> [BusinessCard] {
        let all = try await fetchAllCards()
        return all.filter { $0.tags.contains(where: { $0.name == tagName }) }
    }
    
    // MARK: - Private
    
    private func ensureDirectoryExists(_ url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    private func updateIndex(with id: UUID, updatedAt: Date) throws {
        var index: CardIndex
        if FileManager.default.fileExists(atPath: indexFileURL.path) {
            let data = try Data(contentsOf: indexFileURL)
            index = try Self.makeDecoder().decode(CardIndex.self, from: data)
            if let idx = index.entries.firstIndex(where: { $0.id == id }) {
                index.entries[idx] = .init(id: id, updatedAt: updatedAt)
            } else {
                index.entries.insert(.init(id: id, updatedAt: updatedAt), at: 0)
            }
        } else {
            index = CardIndex(entries: [.init(id: id, updatedAt: updatedAt)])
        }
        try ensureDirectoryExists(cardsDirectory)
        try Self.makeEncoder().encode(index).write(to: indexFileURL)
    }
    
    // MARK: - Coding 辅助（统一 ISO8601，避免编码/解码策略不一致）
    
    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

// MARK: - 图片压缩工具

enum ImageCompressor {
    
    /// 等比缩放 + JPEG 压缩
    static func compress(_ image: UIImage,
                         maxDimension: CGFloat = 1024,
                         quality: CGFloat = 0.7) -> Data? {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
