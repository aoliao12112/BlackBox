//
//  ScannerView.swift
//  blackbox
//
//  Week 3 · 扫描页（真实相机 + PhotosPicker 相册）
//  Spec: spec.md P2 扫描页
//

import SwiftUI
import PhotosUI

struct ScannerView: View {

    @EnvironmentObject private var router: Router
    @StateObject private var camera = CameraManager()

    // 相册选择器状态
    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            // 相机预览（授权通过后显示）
            if camera.isAuthorized {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
            } else {
                // 权限拒绝 / 未决定：占满黑屏 + 提示
                Color.black.ignoresSafeArea()
                permissionDeniedView
            }

            // 底部操作栏（有权限时显示在预览之上）
            if camera.isAuthorized {
                VStack {
                    Spacer()
                    bottomActionBar
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            // 进入页面后：请求权限 → 配置 → 启动
            await camera.requestAuthorization()
            if camera.isAuthorized {
                camera.setupSession()
                camera.start()
            }
        }
        .onDisappear {
            camera.stop()
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let newItem else { return }
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    navigateToBoundary(imageData: data)
                }
                selectedPhotoItem = nil
            }
        }
    }

    // MARK: - 权限拒绝提示

    @ViewBuilder
    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill.badge.ellipsis")
                .font(.system(size: 56))
                .foregroundColor(.gray)
            Text("需要相机权限才能拍摄名片")
                .foregroundColor(.white)
                .font(.headline)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("去设置")
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 8))
            }
            Button("取消") { router.pop() }
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - 底部操作栏

    @ViewBuilder
    private var bottomActionBar: some View {
        HStack(spacing: 40) {
            // 相册
            Button {
                showPhotosPicker = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("相册")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }

            // 拍摄
            Button {
                Task {
                    if let data = try? await camera.capturePhoto() {
                        navigateToBoundary(imageData: data)
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 68, height: 68)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                }
            }

            // 取消
            Button {
                router.pop()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "xmark.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("取消")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func navigateToBoundary(imageData: Data) {
        router.navigate(to: .cardBoundary(imageData: imageData))
    }
}

#Preview {
    NavigationStack {
        ScannerView()
    }
    .environmentObject(Router())
}
