//
//  OCRResultView.swift
//  blackbox
//
//  Week 2 · OCR 原始结果展示骨架 — Week 3 接 VNRecognizeTextRequest
//  Spec: spec.md P4 OCR 结果页
//

import SwiftUI

struct OCRResultView: View {
    
    @EnvironmentObject private var router: Router
    let cardImageData: Data?
    
    @State private var ocrRawText: String = ""
    @State private var isRecognizing = false
    
    var body: some View {
        VStack(spacing: 16) {
            if isRecognizing {
                ProgressView("正在识别文字…")
                    .scaleEffect(1.2)
            } else {
                Text("OCR 原始文本")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView {
                    TextEditor(text: .constant(ocrRawText))
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                HStack(spacing: 16) {
                    Button {
                        router.pop()
                    } label: {
                        Text("重拍")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        // Week 4 TODO: 调 FieldExtractorService 做字段抽取
                        let newCard = BusinessCard.emptyCard()
                        router.navigate(to: .fieldCorrection(card: newCard))
                    } label: {
                        Text("继续 → 字段解析")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(ocrRawText.isEmpty)
                }
            }
        }
        .padding()
        .navigationTitle("识别结果")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await runMockOCR()
        }
    }
    
    private func runMockOCR() async {
        isRecognizing = true
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        // Week 3 TODO: 替换为真实 VNRecognizeTextRequest
        ocrRawText = """
王小明
上海智联科技有限公司
研发总监
Mobile: +86 138-0000-0001
Email: wangxm@zhilian.example.cn
Website: www.zhilian.example.cn
Address: 上海市浦东新区张江高科技园区博云路 2 号
"""
        isRecognizing = false
    }
}

#Preview {
    NavigationStack {
        OCRResultView(cardImageData: nil)
    }
    .environmentObject(Router())
}
