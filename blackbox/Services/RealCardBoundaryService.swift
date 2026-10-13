//
//  RealCardBoundaryService.swift
//  blackbox
//
//  Week 3 · 名片边界检测 + 透视校正（实用简化版）
//  检测用 VNDetectContoursRequest；校正走 bounding box 裁剪 + 缩放
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
        guard let cgImage = image.cgImage else { return nil }

        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.0
        request.detectsDarkOnLight = false  // 名片通常白纸黑字

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try await handler.perform([request])

        guard let observation = request.results?.first else { return nil }

        // 取面积最大的顶层轮廓；若无顶层轮廓则退回整体轮廓
        let contourBox: CGRect
        if let largest = observation.topLevelContours.max(by: { lhs, rhs in
            let lb = lhs.normalizedPath.boundingBox
            let rb = rhs.normalizedPath.boundingBox
            return (lb.width * lb.height) < (rb.width * rb.height)
        }) {
            contourBox = largest.normalizedPath.boundingBox
        } else {
            contourBox = observation.normalizedPath.boundingBox
        }

        // Vision 坐标原点在左下角，UIKit 在左上角 — 翻转 y
        let w = image.size.width
        let h = image.size.height

        let minX = contourBox.minX * w
        let maxX = contourBox.maxX * w
        let minY = (1 - contourBox.maxY) * h
        let maxY = (1 - contourBox.minY) * h

        // 返回四个角点（左上、右上、右下、左下）
        return [
            CGPoint(x: minX, y: minY),
            CGPoint(x: maxX, y: minY),
            CGPoint(x: maxX, y: maxY),
            CGPoint(x: minX, y: maxY)
        ]
    }

    // MARK: 图像校正（简化版：bounding box 裁剪 + aspectFill 缩放）

    func rectifyImage(_ image: UIImage, withCorners corners: [CGPoint]) async throws -> UIImage {
        // 从四个角点取 bounding rect
        let xs = corners.map { $0.x }
        let ys = corners.map { $0.y }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else {
            throw NSError(domain: "RealCardBoundaryService", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "角点数据无效"])
        }

        let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        guard rect.width > 10, rect.height > 10 else {
            throw NSError(domain: "RealCardBoundaryService", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "裁剪区域过小"])
        }

        // 用 Core Graphics 裁剪
        guard let cgImage = image.cgImage else { throw NSError(domain: "RealCardBoundaryService", code: -4) }

        // Vision 坐标的 y 轴和 UIKit 相反，需要转换裁剪 rect
        // 这里输入的 corners 假设已经是 UIKit 坐标（左上角原点）
        let cropRect = CGRect(
            x: rect.origin.x * image.scale,
            y: rect.origin.y * image.scale,
            width: rect.size.width * image.scale,
            height: rect.size.height * image.scale
        )

        guard let croppedCG = cgImage.cropping(to: cropRect) else {
            throw NSError(domain: "RealCardBoundaryService", code: -5,
                          userInfo: [NSLocalizedDescriptionKey: "裁剪失败"])
        }

        // 名片比例目标 1.75:1，取较大边做缩放，保持 aspectFill
        let cardAspect: CGFloat = 1.75
        let cropW = CGFloat(croppedCG.width)
        let cropH = CGFloat(croppedCG.height)

        let targetW: CGFloat
        let targetH: CGFloat
        if cropW / cropH > cardAspect {
            targetW = 600
            targetH = targetW / cardAspect
        } else {
            targetH = 343
            targetW = targetH * cardAspect
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: targetW, height: targetH))
        let result = renderer.image { ctx in
            let aspect = cropW / cropH
            let drawRect: CGRect
            if aspect > cardAspect {
                // 原图更宽，按高度适配
                let h = targetH
                let w = h * aspect
                drawRect = CGRect(x: (targetW - w) / 2, y: 0, width: w, height: h)
            } else {
                let w = targetW
                let h = w / aspect
                drawRect = CGRect(x: 0, y: (targetH - h) / 2, width: w, height: h)
            }
            let uiImage = UIImage(cgImage: croppedCG, scale: image.scale, orientation: .up)
            uiImage.draw(in: drawRect)
        }

        return result
    }
}
