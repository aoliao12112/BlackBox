//
//  CardEditView.swift
//  blackbox
//
//  Week 2 · 名片编辑页骨架
//  Spec: spec.md P7 名片编辑页
//

import SwiftUI

struct CardEditView: View {
    
    @EnvironmentObject private var router: Router
    @State private var card: BusinessCard
    
    let repository: ContactRepositoryProtocol = MockContactRepository()
    
    init(card: BusinessCard) {
        _card = State(initialValue: card)
    }
    
    var body: some View {
        FieldCorrectionView(card: card)
            .navigationTitle("编辑名片")
    }
}

#Preview {
    NavigationStack {
        CardEditView(card: .makeSample(
            name: "王小明",
            company: "上海智联科技",
            mobile: "+86 138-0000-0001"
        ))
    }
}
