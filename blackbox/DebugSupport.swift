//
//  DebugSupport.swift
//  blackbox
//
//  验收取证支持：通过启动参数直达页面/状态，便于用 simctl 自动截图。
//  仅在带启动参数时生效，正常启动无任何影响。
//

import Foundation

enum DebugSupport {

    /// 启动参数预置的搜索关键词（供 SearchView 读取）
    static var initialSearchKeyword: String?

    /// `--reset-cards`：清空名片数据，用于 T01 空状态取证
    static func resetCardsIfRequested(_ args: [String]) {
        guard args.contains("--reset-cards") else { return }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("business_cards", isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
    }

    /// 读取放在 App Documents 下的取证样张（由截图脚本拷入）
    static func imageData(sampleName: String) -> Data? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return try? Data(contentsOf: documents.appendingPathComponent(sampleName))
    }
}
