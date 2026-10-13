//
//  RealCardBoundaryService.swift
//  blackbox
//
//  Week 3 · 名片边界检测 + 透视校正
//  检测使用 VNDetectRectanglesRequest；校正使用 CIPerspectiveCorrection
//

import Foundation
import UIKit
import Vision
import CoreImage

// MARK: - RealCardBoundaryService

/// 名片边界检测与校正服务
final class RealCardBoundaryService: CardBoundaryServiceProtocol {

    // MARK: 边界检测

    func detectCardBoundary(in image: UIImage) async throws -> [CGPoint]? {
        let source = normalizedImage(image)
        guard let cgImage = source.cgImage else { return nil }

        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 5
        request.minimumConfidence = 0.55
        request.minimumSize = 0.18
        request.minimumAspectRatio = 0.35
        request.maximumAspectRatio = 1.0
        request.quadratureTolerance = 30

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try await handler.perform([request])

        guard let rectangle = request.results?.max(by: {
            ($0.boundingBox.width * $0.boundingBox.height) <
            ($1.boundingBox.width * $1.boundingBox.height)
        }) else { return nil }

        let width = source.size.width
        let height = source.size.height
        func uiPoint(_ point: CGPoint) -> CGPoint {
            CGPoint(x: point.x * width, y: (1 - point.y) * height)
        }

        // 固定顺序：左上、右上、右下、左下。
        return [
            uiPoint(rectangle.topLeft),
            uiPoint(rectangle.topRight),
            uiPoint(rectangle.bottomRight),
            uiPoint(rectangle.bottomLeft)
        ]
    }

    // MARK: 图像校正

    func rectifyImage(_ image: UIImage, withCorners corners: [CGPoint]) async throws -> UIImage {
        guard corners.count == 4 else {
            throw NSError(domain: "RealCardBoundaryService", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "需要四个角点"])
        }

        let source = normalizedImage(image)
        guard let input = CIImage(image: source) else {
            throw NSError(domain: "RealCardBoundaryService", code: -4,
                          userInfo: [NSLocalizedDescriptionKey: "无法读取原始图像"])
        }
        let width = source.size.width
        let height = source.size.height
        guard corners.allSatisfy({
            $0.x >= 0 && $0.y >= 0 && $0.x <= width && $0.y <= height
        }) else {
            throw NSError(domain: "RealCardBoundaryService", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "角点超出图像范围"])
        }

        // Core Image 坐标原点在左下角，需要把 UIKit 的 y 坐标翻转。
        func ciVector(_ point: CGPoint) -> CIVector {
            CIVector(x: point.x, y: height - point.y)
        }
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            throw NSError(domain: "RealCardBoundaryService", code: -5,
                          userInfo: [NSLocalizedDescriptionKey: "透视校正滤镜不可用"])
        }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(ciVector(corners[0]), forKey: "inputTopLeft")
        filter.setValue(ciVector(corners[1]), forKey: "inputTopRight")
        filter.setValue(ciVector(corners[2]), forKey: "inputBottomRight")
        filter.setValue(ciVector(corners[3]), forKey: "inputBottomLeft")

        guard let output = filter.outputImage else {
            throw NSError(domain: "RealCardBoundaryService", code: -6,
                          userInfo: [NSLocalizedDescriptionKey: "透视校正失败"])
        }
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(output, from: output.extent) else {
            throw NSError(domain: "RealCardBoundaryService", code: -7,
                          userInfo: [NSLocalizedDescriptionKey: "无法生成校正图像"])
        }
        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    private func normalizedImage(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up || image.scale != 1 else { return image }
        let format = UIGraphicsImageRendererFormat()
        // 统一为 1:1 点/像素，保证 Vision 角点、UIKit 和 Core Image 使用同一坐标系。
        format.scale = 1
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
