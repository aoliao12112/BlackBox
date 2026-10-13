//
//  Router.swift
//  blackbox
//
//  Week 2 · Navigation 路由定义
//

import SwiftUI

/// 应用内导航目标
enum Route: Hashable {
    case scanner                         // 扫描页
    case cardBoundary                    // 名片边界检测
    case ocrResult(cardImageData: Data?) // OCR 结果
    case fieldCorrection(card: BusinessCard) // 字段校正
    case cardDetail(cardID: UUID)        // 名片详情
    case cardEdit(card: BusinessCard)    // 名片编辑
    case search                          // 搜索
}

/// NavigationStack 路径管理
@MainActor
final class Router: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigate(to route: Route) {
        path.append(route)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
