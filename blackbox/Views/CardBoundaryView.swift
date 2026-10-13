//
//  CardBoundaryView.swift
//  blackbox
//
//  Week 3 · 名片边界检测 + 校正 — 接入 RealCardBoundaryService
//  Spec: spec.md P3 名片区域检测与校正
//

import SwiftUI
import UIKit

struct CardBoundaryView: View {

    @EnvironmentObject private var router: Router

    /// 原始拍摄图片（由 ScannerView 传入，nil 时显示占位）
    let originalImageData: Data?

    /// 边界四角，归一化坐标（0~1，相对原图），nil 表示尚未识别
    @State private var corners: [CGPoint]? = nil
    @State private var isManualAdjusting = false
    @State private var dragIndex: Int? = nil
    @State private var dragStart: CGPoint? = nil

    @State private var isDetecting = false
    @State private var isRectifying = false
    @State private var errorMessage: String? = nil

    init(originalImageData: Data? = nil) {
        self.originalImageData = originalImageData
    }

    /// 兜底：未识别到时整张图作为边界（四角全图）
    private static let defaultCorners: [CGPoint] = [
        CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0),
        CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // 背景预览
                Group {
                    if let data = originalImageData,
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                        Text("（无图像）")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)

                // 边界框 + 手动拖拽点
                if let currentCorners = corners {
                    GeometryReader { geo in
                        let containerSize = geo.size
                        let actualImageSize = previewImageSize(for: containerSize)
                        let originX = (containerSize.width - actualImageSize.width) / 2
                        let originY = (containerSize.height - actualImageSize.height) / 2
                        let w = actualImageSize.width
                        let h = actualImageSize.height

                        ZStack {
                            Path { path in
                                let pts = currentCorners.map {
                                    CGPoint(x: originX + $0.x * w, y: originY + $0.y * h)
                                }
                                guard let first = pts.first else { return }
                                path.move(to: first)
                                for p in pts.dropFirst() { path.addLine(to: p) }
                                path.closeSubpath()
                            }
                            .stroke(isManualAdjusting ? Color.orange : Color.green, lineWidth: 3)

                            if isManualAdjusting {
                                ForEach(0..<currentCorners.count, id: \.self) { i in
                                    let display = CGPoint(
                                        x: originX + currentCorners[i].x * w,
                                        y: originY + currentCorners[i].y * h
                                    )
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 26, height: 26)
                                        .overlay(Circle().stroke(Color.orange, lineWidth: 2))
                                        .position(display)
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    if dragIndex != i {
                                                        dragIndex = i
                                                        dragStart = currentCorners[i]
                                                    }
                                                    guard let start = dragStart, w > 0, h > 0 else { return }
                                                    var c = start
                                                    c.x = min(max(c.x + value.translation.width / w, 0), 1)
                                                    c.y = min(max(c.y + value.translation.height / h, 0), 1)
                                                    if var arr = corners { arr[i] = c; corners = arr }
                                                }
                                                .onEnded { _ in
                                                    dragIndex = nil
                                                    dragStart = nil
                                                }
                                        )
                                }
                            }
                        }
                    }
                    .padding(24)
                }

                // 状态提示
                if isDetecting {
                    ProgressView("正在检测名片边界…")
                        .scaleEffect(1.2)
                } else if let errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("手动调整") { enterManualMode() }
                            .buttonStyle(.bordered)
                        Button("重新检测") {
                            Task { await detectBoundary() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                } else if isManualAdjusting {
                    VStack {
                        Text("拖动四角调整边界")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)
                } else if corners != nil {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        Text("名片边界已识别")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)
                }
            }

            Spacer()

            // 底部按钮
            HStack(spacing: 16) {
                Button(isManualAdjusting ? "完成调整" : "手动调整") {
                    toggleManualMode()
                }
                .buttonStyle(.bordered)
                .disabled(corners == nil && originalImageData == nil)

                Spacer()

                Button {
                    Task { await confirmAndRectify() }
                } label: {
                    if isRectifying {
                        ProgressView()
                    } else {
                        Text("确认校正 →")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(corners == nil || isRectifying)
            }
            .padding()
        }
        .navigationTitle("边界检测")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("重拍") { router.popToRoot(); router.navigate(to: .scanner) }
            }
        }
        .task {
            await detectBoundary()
        }
    }

    // MARK: - 手动调整

    private func enterManualMode() {
        errorMessage = nil
        if corners == nil { corners = Self.defaultCorners }
        isManualAdjusting = true
    }

    private func toggleManualMode() {
        if isManualAdjusting {
            isManualAdjusting = false
        } else {
            enterManualMode()
        }
    }

    // MARK: - 辅助

    /// 实际图片点数尺寸（按真实图计算，避免硬编码导致边界框错位）
    private var sourceImageSize: CGSize {
        if let data = originalImageData, let image = UIImage(data: data) {
            return image.size
        }
        return CGSize(width: 3024, height: 4032) // 无图像时兜底
    }

    private func previewImageSize(for container: CGSize) -> CGSize {
        let containerAspect = container.width / container.height
        let imageAspect = sourceImageSize.width / sourceImageSize.height
        if containerAspect > imageAspect {
            let h = container.height - 48
            return CGSize(width: h * imageAspect, height: h)
        } else {
            let w = container.width - 48
            return CGSize(width: w, height: w / imageAspect)
        }
    }

    private func detectBoundary() async {
        isDetecting = true
        errorMessage = nil
        defer { isDetecting = false }

        guard let data = originalImageData,
              let image = UIImage(data: data) else {
            errorMessage = "未检测到名片，请手动调整"
            return
        }

        let service = RealCardBoundaryService()
        do {
            if let detected = try await service.detectCardBoundary(in: image) {
                let size = image.size
                corners = detected.map {
                    CGPoint(x: $0.x / size.width, y: $0.y / size.height)
                }
            } else {
                errorMessage = "未检测到名片，请手动调整"
            }
        } catch {
            errorMessage = "检测失败：\(error.localizedDescription)"
        }
    }

    private func confirmAndRectify() async {
        guard let data = originalImageData,
              let image = UIImage(data: data),
              let corners else { return }

        isRectifying = true
        defer { isRectifying = false }

        // 归一化 → 原图点坐标，用于 rectifyImage
        let size = image.size
        let pointCorners = corners.map {
            CGPoint(x: $0.x * size.width, y: $0.y * size.height)
        }

        let service = RealCardBoundaryService()
        do {
            let rectified = try await service.rectifyImage(image, withCorners: pointCorners)
            guard let jpegData = rectified.jpegData(compressionQuality: 0.8) else {
                errorMessage = "图像压缩失败"
                return
            }
            router.navigate(to: .ocrResult(cardImageData: jpegData, originalImageData: data))
        } catch {
            errorMessage = "校正失败：\(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        CardBoundaryView()
    }
    .environmentObject(Router())
}