//
//  RealOCRService.swift
//  blackbox
//
//  Week 3 · 真实 OCR 实现（VNRecognizeTextRequest）
//

import Foundation
import UIKit
import Vision

// MARK: - RealOCRService

/// 基于系统 Vision 框架的文字识别服务
final class RealOCRService: OCRServiceProtocol {

    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "RealOCRService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法从 UIImage 获取 CGImage"])
        }

        // 配置识别请求
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try await handler.perform([request])

        let observations = (request.results ?? []) as [VNRecognizedTextObservation]

        // 构造文字块
        var blocks: [OCRResult.OCRTextBlock] = []
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            blocks.append(
                OCRResult.OCRTextBlock(
                    text: topCandidate.string,
                    confidence: Double(topCandidate.confidence),
                    boundingBox: observation.boundingBox
                )
            )
        }

        // 拼接原始文本
        let rawText = blocks.map(\.text).joined(separator: "\n")

        // 推断语言：只要出现中文字符就认为是 zh-Hans
        let hasChinese = rawText.range(of: "\\p{Han}", options: .regularExpression) != nil
        let language: String = hasChinese ? "zh-Hans" : "en"

        return OCRResult(rawText: rawText, textBlocks: blocks, language: language)
    }
}
