//
//  CameraManager.swift
//  blackbox
//
//  Week 3 · AVCaptureSession 封装，负责相机权限、会话配置与拍照
//

import AVFoundation
import Foundation
import Combine

/// 相机相关错误
enum CameraError: LocalizedError {
    case authorizationDenied              // 权限被拒绝
    case deviceUnavailable                // 设备不可用
    case captureFailed                    // 捕获失败

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:  return "相机权限被拒绝"
        case .deviceUnavailable:    return "相机设备不可用"
        case .captureFailed:        return "照片捕获失败"
        }
    }
}

/// 管理 AVCaptureSession、权限查询与拍照
@MainActor
final class CameraManager: ObservableObject {

    // MARK: - 公开属性

    /// 原始会话，供 CameraPreviewView 预览层使用
    let session = AVCaptureSession()

    /// 是否已授权
    @Published var isAuthorized: Bool = false

    /// 当前授权状态
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined

    /// 最近一次发生的错误
    @Published var error: CameraError?

    // MARK: - 私有属性

    /// 拍照输出，setupSession 后注入
    private var photoOutput: AVCapturePhotoOutput?

    /// 串行队列：配置和 startSession 都放这里
    private let sessionQueue = DispatchQueue(label: "camera.session")

    // MARK: - 权限

    /// 查询当前相机权限状态并更新 Published
    func checkAuthorization() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = status
        isAuthorized = status == .authorized
        if status == .denied || status == .restricted {
            error = .authorizationDenied
        }
    }

    /// 异步请求相机权限；完成后更新 Published
    func requestAuthorization() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        authorizationStatus = granted ? .authorized : .denied
        isAuthorized = granted
        if !granted {
            error = .authorizationDenied
        }
    }

    // MARK: - Session

    /// 配置 session（.photo 模式，后置摄像头优先）
    func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }

            self.session.sessionPreset = .photo

            // 扫描纸质名片必须优先使用后置摄像头；无后摄环境再回退。
            let device: AVCaptureDevice? = {
                let back = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                return back ?? AVCaptureDevice.default(for: .video)
            }()

            guard let device else {
                Task { @MainActor in self.error = .deviceUnavailable }
                return
            }

            // 添加 input
            guard let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                Task { @MainActor in self.error = .deviceUnavailable }
                return
            }
            self.session.addInput(input)

            // 添加 photo output
            let output = AVCapturePhotoOutput()
            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
                self.photoOutput = output
            }
        }
    }

    /// 在串行队列里启动会话
    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    /// 停止会话
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: - 拍照

    /// 拍一张照片，返回 JPEG Data
    func capturePhoto() async throws -> Data {
        guard let photoOutput else {
            throw CameraError.deviceUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureContinuation(continuation: continuation))
        }
    }
}

// MARK: - 私有辅助：PhotoCaptureContinuation

/// 把 AVCapturePhotoCaptureDelegate 桥接到 Swift Concurrency
private final class PhotoCaptureContinuation: NSObject, AVCapturePhotoCaptureDelegate {
    private let continuation: CheckedContinuation<Data, Error>

    init(continuation: CheckedContinuation<Data, Error>) {
        self.continuation = continuation
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            continuation.resume(throwing: error)
            return
        }
        guard let data = photo.fileDataRepresentation() else {
            continuation.resume(throwing: CameraError.captureFailed)
            return
        }
        continuation.resume(returning: data)
    }
}
