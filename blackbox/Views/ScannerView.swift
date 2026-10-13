//
//  ScannerView.swift
//  blackbox
//
//  Week 2 · 扫描页骨架 — Week 3 接 AVCamera
//  Spec: spec.md P2 扫描页
//

import SwiftUI

struct ScannerView: View {
    
    @EnvironmentObject private var router: Router
    @State private var showPhotoPicker = false
    
    var body: some View {
        ZStack {
            // 相机预览区域占位（Week 3 替换为 AVCaptureSession）
            Color.black.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // 底部操作栏
                HStack(spacing: 40) {
                    // 相册导入
                    Button {
                        showPhotoPicker = true
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
                    
                    // 拍摄按钮
                    Button {
                        // Week 3 TODO: 调用 AVCamera 拍一张
                        navigateToBoundary()
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
                    
                    // 占位保持对齐
                    VStack(spacing: 4) {
                        Image(systemName: "flashlight.off.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("")
                            .font(.caption)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { router.pop() }
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPhotoPicker) {
            // Week 3: 用 PhotosPicker 替换
            Text("相册选择器（Week 3 实现）")
                .onTapGesture { navigateToBoundary() }
        }
    }
    
    private func navigateToBoundary() {
        router.navigate(to: .cardBoundary)
    }
}

#Preview {
    NavigationStack {
        ScannerView()
    }
    .environmentObject(Router())
}
