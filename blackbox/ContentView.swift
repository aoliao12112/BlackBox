//
//  ContentView.swift
//  blackbox
//
//  Week 2 · NavigationStack 根 + 路由注入
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var router = Router()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .scanner:
                        ScannerView()
                    case .cardBoundary:
                        CardBoundaryView()
                    case .ocrResult(let data):
                        OCRResultView(cardImageData: data)
                    case .fieldCorrection(let card):
                        FieldCorrectionView(card: card)
                    case .cardDetail(let id):
                        CardDetailView(cardID: id)
                    case .cardEdit(let card):
                        CardEditView(card: card)
                    case .search:
                        SearchView()
                    }
                }
        }
        .environmentObject(router)
    }
}

#Preview {
    ContentView()
}
