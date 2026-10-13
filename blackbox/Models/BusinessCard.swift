//
//  BusinessCard.swift
//  blackbox
//
//  Created by admin on 2026/10/13.
//
//  Spec reference: BlackBoxSpec/spec.md §4

import Foundation
import UIKit

// MARK: - 名片数据模型

/// 名片完整数据结构
/// AI/OCR 功能字段允许为 nil，禁止 AI "补全" 原图不存在的信息
struct BusinessCard: Identifiable, Codable, Hashable {
    var id: UUID                    // 唯一标识
    
    // 图像（压缩存储，可选）
    var originalImageData: Data?    // 原始拍摄图片
    var processedImageData: Data?   // 经边界检测 + 校正后的图片
    
    // MARK: - 结构化联系字段
    // 所有字段均允许 nil，AI 不允许补全原图中不存在的信息
    
    var name: String?               // 姓名
    var company: String?            // 公司
    var jobTitle: String?           // 职位
    var department: String?         // 部门（可选字段）
    var mobile: String?             // 手机号码
    var officePhone: String?        // 办公电话
    var fax: String?                // 传真（可选字段）
    var email: String?              // 电子邮箱
    var website: String?            // 网址
    var address: String?            // 地址
    var postalCode: String?         // 邮编（可选字段）
    
    // MARK: - 管理字段
    
    var tags: [Tag]                 // 标签列表
    var notes: String?              // 备注
    var createdAt: Date             // 创建时间
    var updatedAt: Date?            // 最后更新时间
    
    // MARK: - AI/OCR 溯源（用于概率性分析）
    
    var ocrRawText: String?         // OCR 原始文本
    var fieldConfidence: [FieldConfidence]?  // 各字段置信度
    
    // MARK: - Factory
    
    /// 创建一张空白名片（用于人工手动录入）
    static func emptyCard() -> BusinessCard {
        BusinessCard(
            id: UUID(),
            originalImageData: nil,
            processedImageData: nil,
            name: nil,
            company: nil,
            jobTitle: nil,
            department: nil,
            mobile: nil,
            officePhone: nil,
            fax: nil,
            email: nil,
            website: nil,
            address: nil,
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

// MARK: - 标签

struct Tag: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String?
}

// MARK: - 字段置信度

/// 用于记录 AI 输出的概率性，便于后续错误分析
struct FieldConfidence: Codable, Hashable {
    let fieldName: String           // 如 "name", "company", "mobile"
    let rawValue: String            // AI 解析的原始值
    let confidence: Double          // 0.0 ~ 1.0
    let source: Source              // 识别来源
    
    enum Source: String, Codable {
        case ocr                    // 纯 OCR 识别
        case llm                    // LLM 字段抽取
        case manual                 // 用户手动输入/修正
        case hybrid                 // OCR + LLM 结合
    }
}

// MARK: - 搜索可匹配字段扩展

extension BusinessCard {
    /// 搜索关键词匹配范围（用于 SearchView）
    func matches(_ keyword: String) -> Bool {
        let lower = keyword.trimmingCharacters(in: .whitespaces).lowercased()
        guard !lower.isEmpty else { return true }
        
        return [
            name, company, jobTitle, mobile, officePhone, email, website, address
        ].compactMap { $0?.lowercased() }.contains { $0.contains(lower) }
    }
    
    /// 返回非空的联系字段字典（用于调试 / 导出）
    func nonEmptyFields() -> [(String, String)] {
        var result: [(String, String)] = []
        let mirror = Mirror(reflecting: self)
        
        // 只抽取联系字段（排除 id / 时间戳 / tags / 图片等）
        let contactKeys: Set<String> = [
            "name", "company", "jobTitle", "department",
            "mobile", "officePhone", "fax",
            "email", "website", "address", "postalCode"
        ]
        
        for child in mirror.children {
            guard let label = child.label,
                  contactKeys.contains(label),
                  let value = child.value as? String,
                  !value.isEmpty else { continue }
            result.append((label, value))
        }
        return result
    }
}
