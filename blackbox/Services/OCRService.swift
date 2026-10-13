//
//  OCRService.swift
//  blackbox
//
//  Created by admin on 2026/10/13.
//
//  Week 1 骨架：Protocol 定义，Week 3 实现
//

import Foundation
import UIKit

// MARK: - OCR 服务协议

/// OCR 文字识别服务
/// Week 3 实现（可选方案：系统 VNRecognizeTextRequest / 第三方 API）
protocol OCRServiceProtocol {
    
    /// 从图像中识别文字，返回原始 OCR 文本
    /// - Parameter image: 输入图像（应为已校正的名片图）
    /// - Returns: OCR 原始文本 + 各框选文字块 + 置信度
    func recognizeText(from image: UIImage) async throws -> OCRResult
}

/// OCR 原始结果
struct OCRResult {
    let rawText: String                     // 整图拼接文本
    let textBlocks: [OCRTextBlock]          // 各文字块（用于调试）
    let language: String?                    // 识别到的主要语言
    
    struct OCRTextBlock {
        let text: String
        let confidence: Double               // 0.0 ~ 1.0
        let boundingBox: CGRect              // 图像上的位置
    }
}

// MARK: - 名片边界检测服务

/// 检测名片在图像中的边界（四边形）并做透视校正
/// Week 3 实现
protocol CardBoundaryServiceProtocol {
    
    /// 检测图像中名片的四条边
    /// - Parameter image: 原始拍摄图像
    /// - Returns: 名片四个顶点坐标（四边形），失败返回 nil（需手动调整）
    func detectCardBoundary(in image: UIImage) async throws -> [CGPoint]?
    
    /// 根据四个顶点做透视校正（矩形裁剪 + 方向修正）
    func rectifyImage(_ image: UIImage, withCorners corners: [CGPoint]) async throws -> UIImage
}

// MARK: - 字段抽取服务

/// 将 OCR 原始文本解析为结构化联系字段
/// Week 4 实现
/// ⚠️ 关键约束：禁止 AI "补全" 原图不存在的字段
protocol FieldExtractorServiceProtocol {
    
    /// 从 OCR 结果中抽取结构化字段
    /// - Parameter ocrResult: OCR 原始结果
    /// - Returns: 结构化字段 + 各字段置信度；无法确认的字段必须返回 nil
    func extractFields(from ocrResult: OCRResult) async throws -> FieldExtractionResult
}

/// 字段抽取结果
struct FieldExtractionResult {
    var name: String?
    var company: String?
    var jobTitle: String?
    var mobile: String?
    var officePhone: String?
    var email: String?
    var website: String?
    var address: String?
    
    /// 每个字段的置信度和来源
    var fieldConfidence: [FieldConfidence]
}
