//
//  CardBoundaryView.swift
//  blackbox
//
//  Week 2 · 名片边界检测 + 校正骨架 — Week 3 实现真实检测
//  Spec: spec.md P3 名片区域检测与校正
//

import SwiftUI

struct CardBoundaryView: View {
    
    @EnvironmentObject private var router: Router
    @State private var autoDetected = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 图像预览区
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .padding(24)
                
                if autoDetected {
                    // 模拟检测框
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.green, lineWidth: 2)
                        .padding(48)
                    
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        Text("名片边界已识别")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("正在检测名片边界…")
                        .foregroundStyle(.secondary)
                        .onAppear {
                            // Week 3 TODO: 调用 CardBoundaryService
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                autoDetected = true
                            }
                        }
                }
            }
            
            Spacer()
            
            // 底部按钮
            HStack(spacing: 16) {
                Button("手动调整") {
                    // Week 3 TODO: 手动拖拽四角校正
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("确认校正") {
                    router.navigate(to: .ocrResult(cardImageData: nil))
                }
                .buttonStyle(.borderedProminent)
                .disabled(!autoDetected)
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
    }
}

#Preview {
    NavigationStack {
        CardBoundaryView()
    }
    .environmentObject(Router())
}
