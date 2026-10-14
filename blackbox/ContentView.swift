//
//  ContentView.swift
//  blackbox
//
//  Week 2 · NavigationStack 根 + 路由注入
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var router: Router

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        var initialRoute: Route?
        if arguments.contains("--screenshot-scanner") {
            initialRoute = .scanner
        } else if let flag = arguments.firstIndex(of: "--screenshot-card-id"),
                  arguments.indices.contains(flag + 1),
                  let id = UUID(uuidString: arguments[flag + 1]) {
            initialRoute = .cardDetail(cardID: id)
        }
        _router = StateObject(wrappedValue: Router(initialRoute: initialRoute))
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
    }
}

#Preview {
    ContentView()
}
