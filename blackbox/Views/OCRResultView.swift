//
//  OCRResultView.swift
//  blackbox
//
//  Week 3 · OCR 结果页 — 接入 RealOCRService（VNRecognizeTextRequest）
//  Spec: spec.md P4 OCR 结果页
//

import SwiftUI
import UIKit

struct OCRResultView: View {

    @EnvironmentObject private var router: Router
    let cardImageData: Data?
    let originalImageData: Data?

    @State private var ocrRawText: String = ""
    @State private var isRecognizing = false
    @State private var isExtracting = false
    @State private var errorMessage: String? = nil
    @State private var language: String? = nil

    init(cardImageData: Data?, originalImageData: Data? = nil) {
        self.cardImageData = cardImageData
        self.originalImageData = originalImageData
    }

    var body: some View {
        VStack(spacing: 16) {
            if isRecognizing {
                ProgressView("正在识别文字…")
                    .scaleEffect(1.2)
            } else if let errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("识别失败")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("重试") {
                        Task { await runRealOCR() }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
            } else {
                if let image = cardImage() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                HStack {
                    Text("OCR 原始文本")
                        .font(.headline)
                    Spacer()
                    if let language {
                        Text("语言: \(language)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

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
                        Task { await proceedToCorrection() }
                    } label: {
                        if isExtracting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("继续 → 字段解析")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(ocrRawText.isEmpty || isExtracting)
                }
            }
        }
        .padding()
        .navigationTitle("识别结果")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await runRealOCR()
        }
    }

    private func cardImage() -> UIImage? {
        if let data = cardImageData, let image = UIImage(data: data) { return image }
        if let data = originalImageData, let image = UIImage(data: data) { return image }
        return nil
    }

    private func runRealOCR() async {
        isRecognizing = true
        errorMessage = nil
        defer { isRecognizing = false }

        guard let data = cardImageData,
              let image = UIImage(data: data) else {
            errorMessage = "未提供图像数据"
            return
        }

        let ocrService = RealOCRService()
        do {
            let result = try await ocrService.recognizeText(from: image)
            ocrRawText = result.rawText
            language = result.language
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 字段抽取：调 RuleBasedFieldExtractor，把 OCR 文本解析为结构化字段后跳转校正页
    private func proceedToCorrection() async {
        isExtracting = true
        defer { isExtracting = false }

        let ocrResult = OCRResult(rawText: ocrRawText, textBlocks: [], language: language)

        var card = BusinessCard.emptyCard()
        card.processedImageData = cardImageData
        card.originalImageData = originalImageData
        card.ocrRawText = ocrRawText

        let extractor = RuleBasedFieldExtractor()
        do {
            let extracted = try await extractor.extractFields(from: ocrResult)
            card.name = extracted.name
            card.company = extracted.company
            card.jobTitle = extracted.jobTitle
            card.mobile = extracted.mobile
            card.officePhone = extracted.officePhone
            card.fax = extracted.fax
            card.email = extracted.email
            card.additionalEmails = extracted.additionalEmails.isEmpty ? nil : extracted.additionalEmails
            card.website = extracted.website
            card.address = extracted.address
            card.fieldConfidence = extracted.fieldConfidence.isEmpty ? nil : extracted.fieldConfidence
        } catch {
            // 抽取失败也继续，让用户在校正页手动填写；字段保持 nil
        }

        router.navigate(to: .fieldCorrection(card: card))
    }
}

#Preview {
    NavigationStack {
        OCRResultView(cardImageData: nil)
    }
    .environmentObject(Router())
}
