//
//  EndToEndScanValidationTests.swift
//  blackboxTests
//
//  端到端扫描验证：对 Tests/GroundTruth 的全部测试名片跑真实管线
//  原图 → 边界检测 → 透视校正 → Vision OCR → 规则字段抽取 → 导出 actual JSON
//
//  产物写入 App 容器 Documents/ActualResults/<card_id>.json，
//  再由 Scripts/evaluate_accuracy.py 与 GroundTruth 逐字段比对。
//

import UIKit
import XCTest
@testable import blackbox

@MainActor
final class EndToEndScanValidationTests: XCTestCase {

    /// 测试包内的 GroundTruth 资源目录（Tests/GroundTruth 以文件夹引用方式打包）
    private func groundTruthDirectory() throws -> URL {
        let bundle = Bundle(for: Self.self)
        guard let url = bundle.url(forResource: "GroundTruth", withExtension: nil),
              FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(domain: "EndToEndScanValidationTests", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "测试包内缺少 GroundTruth 资源"])
        }
        return url
    }

    private func jsonValue(_ value: String?) -> Any {
        value.map { $0 as Any } ?? NSNull()
    }

    /// 复刻真实扫描链路：detectCardBoundary → rectifyImage(JPEG 0.8) → recognizeText → extractFields
    func testScanAllGroundTruthCardsAndExportActualResults() async throws {
        let groundTruth = try groundTruthDirectory()
        let images = try FileManager.default
            .contentsOfDirectory(at: groundTruth, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "jpg" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        XCTAssertEqual(images.count, 35, "期望读取到 35 张测试名片")

        let outputDirectory = try FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ActualResults", isDirectory: true)
        try? FileManager.default.removeItem(at: outputDirectory)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let boundaryService = RealCardBoundaryService()
        let ocrService = RealOCRService()
        let extractor = RuleBasedFieldExtractor()

        var exported = 0
        var emptyOCR: [String] = []
        var boundaryMisses: [String] = []

        for imageURL in images {
            let cardID = imageURL.deletingPathExtension().lastPathComponent

            guard let original = UIImage(contentsOfFile: imageURL.path) else {
                XCTFail("无法读取测试图片 \(imageURL.lastPathComponent)")
                continue
            }

            // 真实应用：先做边界检测 + 透视校正，再对校正图做 OCR（JPEG 0.8 往返）。
            // 检测失败时退回原图，等价于用户手动跳过校正。
            var cardImage = original
            var didRectify = false
            if let corners = try? await boundaryService.detectCardBoundary(in: original),
               corners.count == 4,
               let rectified = try? await boundaryService.rectifyImage(original, withCorners: corners),
               let jpeg = rectified.jpegData(compressionQuality: 0.8),
               let roundTripped = UIImage(data: jpeg) {
                cardImage = roundTripped
                didRectify = true
            } else {
                boundaryMisses.append(cardID)
            }

            let ocrResult = try await ocrService.recognizeText(from: cardImage)
            let rawText = ocrResult.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
            if rawText.isEmpty { emptyOCR.append(cardID) }

            let fields = try await extractor.extractFields(from: ocrResult)
            let actual: [String: Any] = [
                "name": jsonValue(fields.name),
                "company": jsonValue(fields.company),
                "jobTitle": jsonValue(fields.jobTitle),
                "mobile": jsonValue(fields.mobile),
                "officePhone": jsonValue(fields.officePhone),
                "fax": jsonValue(fields.fax),
                "email": jsonValue(fields.email),
                "additionalEmails": fields.additionalEmails,
                "website": jsonValue(fields.website),
                "address": jsonValue(fields.address),
            ]
            let document: [String: Any] = [
                "actual": actual,
                "meta": [
                    "usedBoundaryRectification": didRectify,
                    "language": ocrResult.language ?? "",
                    "textBlockCount": ocrResult.textBlocks.count,
                    "ocrRawText": ocrResult.rawText,
                ],
            ]

            let data = try JSONSerialization.data(
                withJSONObject: document, options: [.prettyPrinted, .sortedKeys]
            )
            try data.write(to: outputDirectory.appendingPathComponent("\(cardID).json"))
            exported += 1
            print("E2E_EXPORTED \(cardID) rectified=\(didRectify) textLen=\(rawText.count)")
        }

        print("E2E_SUMMARY exported=\(exported) boundaryMisses=\(boundaryMisses.count) emptyOCR=\(emptyOCR.count) outDir=\(outputDirectory.path)")
        if !boundaryMisses.isEmpty { print("E2E_BOUNDARY_MISS \(boundaryMisses.joined(separator: ","))") }
        if !emptyOCR.isEmpty { print("E2E_EMPTY_OCR \(emptyOCR.joined(separator: ","))") }

        XCTAssertEqual(exported, 35, "应导出全部 35 张名片的结果")
        XCTAssertTrue(emptyOCR.isEmpty, "存在 OCR 完全无文字的卡片：\(emptyOCR)")
    }
}
