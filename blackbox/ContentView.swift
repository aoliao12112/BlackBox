//
//  ContentView.swift
//  blackbox
//
//  Week 2 · NavigationStack 根 + 路由注入
//  验收取证：支持启动参数直达页面（见 DebugSupport.swift）
//

import SwiftUI
import UIKit

struct ContentView: View {

    @StateObject private var router: Router
    @State private var bootstrap: Bootstrap
    @State private var isBootstrapping = false

    /// 需要异步准备数据后才能进入的路由（OCR 抽取 / 按 id 取卡片）
    enum Bootstrap: Equatable {
        case none
        case fieldCorrection(sampleName: String)
        case editCard(id: UUID)
        case exportCard(id: UUID)
    }

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        DebugSupport.resetCardsIfRequested(arguments)

        func value(_ flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag),
                  arguments.indices.contains(index + 1) else { return nil }
            return arguments[index + 1]
        }

        var initialRoute: Route?
        var bootstrap: Bootstrap = .none

        if let route = value("--route") {
            switch route {
            case "scanner":
                initialRoute = .scanner
            case "boundary":
                if let sample = value("--sample-image") {
                    initialRoute = .cardBoundary(imageData: DebugSupport.imageData(sampleName: sample))
                }
            case "ocr":
                if let sample = value("--sample-image") {
                    let data = DebugSupport.imageData(sampleName: sample)
                    initialRoute = .ocrResult(cardImageData: data, originalImageData: data)
                }
            case "correction":
                if let sample = value("--sample-image") {
                    bootstrap = .fieldCorrection(sampleName: sample)
                }
            case "detail":
                if let id = value("--card-id").flatMap(UUID.init(uuidString:)) {
                    initialRoute = .cardDetail(cardID: id)
                }
            case "edit":
                if let id = value("--card-id").flatMap(UUID.init(uuidString:)) {
                    bootstrap = .editCard(id: id)
                }
            case "export":
                if let id = value("--card-id").flatMap(UUID.init(uuidString:)) {
                    bootstrap = .exportCard(id: id)
                }
            case "search":
                DebugSupport.initialSearchKeyword = value("--search-keyword") ?? ""
                initialRoute = .search
            case "tagManager":
                initialRoute = .tagManager
            case "tagFilter":
                if let tag = value("--tag-name") {
                    initialRoute = .tagFilter(tagName: tag)
                }
            default:
                break
            }
        }

        // 兼容既有截图参数
        if initialRoute == nil, bootstrap == .none {
            if arguments.contains("--screenshot-scanner") {
                initialRoute = .scanner
            } else if let id = value("--screenshot-card-id").flatMap(UUID.init(uuidString:)) {
                initialRoute = .cardDetail(cardID: id)
            }
        }

        _router = StateObject(wrappedValue: Router(initialRoute: initialRoute))
        _bootstrap = State(initialValue: bootstrap)
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .scanner:
                        ScannerView()
                    case .cardBoundary(let imageData):
                        CardBoundaryView(originalImageData: imageData)
                    case .ocrResult(let data, let originalImageData):
                        OCRResultView(cardImageData: data, originalImageData: originalImageData)
                    case .fieldCorrection(let card):
                        FieldCorrectionView(card: card)
                    case .cardDetail(let id):
                        CardDetailView(cardID: id)
                    case .cardEdit(let card):
                        CardEditView(card: card)
                    case .export(let card):
                        ExportView(card: card)
                    case .search:
                        SearchView()
                    case .tagManager:
                        TagManagerView()
                    case .tagFilter(let tagName):
                        TagFilterView(tagName: tagName)
                    }
                }
        }
        .environmentObject(router)
        .task { await runBootstrap() }
    }

    /// 异步准备需要数据的路由，然后推入导航栈
    private func runBootstrap() async {
        switch bootstrap {
        case .none:
            return

        case .fieldCorrection(let sampleName):
            guard let data = DebugSupport.imageData(sampleName: sampleName),
                  let image = UIImage(data: data) else { return }
            isBootstrapping = true
            defer { isBootstrapping = false }

            var card = BusinessCard.emptyCard()
            card.processedImageData = data
            card.originalImageData = data

            let ocrResult = try? await RealOCRService().recognizeText(from: image)
            card.ocrRawText = ocrResult?.rawText
            if let ocrResult,
               let extracted = try? await RuleBasedFieldExtractor().extractFields(from: ocrResult) {
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
            }
            router.navigate(to: .fieldCorrection(card: card))

        case .editCard(let id):
            isBootstrapping = true
            defer { isBootstrapping = false }
            if let card = try? await FileManagerContactRepository.shared.fetchCard(id: id) {
                router.navigate(to: .cardEdit(card: card))
            }

        case .exportCard(let id):
            isBootstrapping = true
            defer { isBootstrapping = false }
            if let card = try? await FileManagerContactRepository.shared.fetchCard(id: id) {
                router.navigate(to: .export(card: card))
            }
        }
    }
}

#Preview {
    ContentView()
}
