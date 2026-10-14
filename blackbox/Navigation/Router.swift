//
//  Router.swift
//  blackbox
//
//  Week 2 · Navigation 路由定义
//

import SwiftUI
import Combine

/// 应用内导航目标
enum Route: Hashable {
    case scanner                                 // 扫描页
    case cardBoundary(imageData: Data?)          // 名片边界检测（接 Scanner 传来的图片）
    case ocrResult(cardImageData: Data?, originalImageData: Data?)  // OCR 结果（校正图 + 原图）
    case fieldCorrection(card: BusinessCard)     // 字段校正
    case cardDetail(cardID: UUID)                // 名片详情
    case cardEdit(card: BusinessCard)            // 名片编辑
    case export(card: BusinessCard)              // 导出
    case search                                  // 搜索
    case tagManager                              // 标签管理
    case tagFilter(tagName: String)              // 按标签筛选
}

/// NavigationStack 路径管理
final class Router: ObservableObject {
    @Published var path = NavigationPath()

    init(initialRoute: Route? = nil) {
        if let initialRoute { path.append(initialRoute) }
    }
    
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
