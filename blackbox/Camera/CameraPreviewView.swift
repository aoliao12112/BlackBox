//
//  CameraPreviewView.swift
//  blackbox
//
//  Week 3 · AVCaptureVideoPreviewLayer 的 SwiftUI 包装
//

import AVFoundation
import SwiftUI

/// 承载预览层的 UIView，负责在尺寸变化时同步 layer 的 frame
private final class PreviewContainerView: UIView {
    let previewLayer: AVCaptureVideoPreviewLayer

    init(session: AVCaptureSession) {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.previewLayer = layer
        super.init(frame: .zero)
        backgroundColor = .black
        self.layer.addSublayer(layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

/// 相机预览层：把 AVCaptureVideoPreviewLayer 塞进 UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        PreviewContainerView(session: session)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let container = uiView as? PreviewContainerView else { return }
        if container.previewLayer.session !== session {
            container.previewLayer.session = session
        }
    }
}

#Preview {
    // 占位预览：因为 session 未启动，这里显示黑色背景
    CameraPreviewView(session: AVCaptureSession())
        .ignoresSafeArea()
}