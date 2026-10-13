//
//  RuleBasedFieldExtractor.swift
//  blackbox
//
//  Week 4 · 字段抽取引擎（规则引擎 v1）
//  把 OCR 原始文本解析为结构化字段；识别不到的一律返回 nil，禁止补全
//

import Foundation

// MARK: - 规则字段抽取器

/// 基于正则 + 关键词的本地规则抽取器
/// 核心约束：只做确定性匹配，「匹配不到就 nil」，绝不猜测补全原图不存在的信息
final class RuleBasedFieldExtractor: FieldExtractorServiceProtocol {

    func extractFields(from ocrResult: OCRResult) async throws -> FieldExtractionResult {
        let lines = ocrResult.rawText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var result = FieldExtractionResult(
            name: nil, company: nil, jobTitle: nil,
            mobile: nil, officePhone: nil, fax: nil,
            email: nil, website: nil, address: nil,
            fieldConfidence: []
        )

        // 记录某一行已被哪个字段占用，避免重复抽取（姓名排除法用）
        var consumed: [Int: String] = [:]

        for (idx, line) in lines.enumerated() {
            // 优先级：email > website > mobile > officePhone > 传真 > 地址 > 公司 > 职位
            if consumed[idx] != nil { continue }

            if result.email == nil, let v = Self.extractEmail(line) {
                result.email = v; consumed[idx] = "email"
                add(&result, field: "email", value: v, confidence: 0.95)
            } else if result.website == nil, let v = Self.extractWebsite(line) {
                result.website = v; consumed[idx] = "website"
                add(&result, field: "website", value: v, confidence: 0.90)
            } else if result.mobile == nil, let v = Self.extractMobile(line) {
                result.mobile = v; consumed[idx] = "mobile"
                add(&result, field: "mobile", value: v, confidence: 0.92)
            } else if result.fax == nil, let v = Self.extractFax(line) {
                result.fax = v; consumed[idx] = "fax"
                add(&result, field: "fax", value: v, confidence: 0.85)
            } else if result.officePhone == nil, let v = Self.extractOfficePhone(line) {
                result.officePhone = v; consumed[idx] = "officePhone"
                add(&result, field: "officePhone", value: v, confidence: 0.85)
            } else if result.address == nil, let v = Self.extractAddress(line) {
                result.address = v; consumed[idx] = "address"
                add(&result, field: "address", value: v, confidence: 0.70)
            } else if result.company == nil, let v = Self.extractCompany(line) {
                result.company = v; consumed[idx] = "company"
                add(&result, field: "company", value: v, confidence: 0.65)
            } else if result.jobTitle == nil, let v = Self.extractJobTitle(line) {
                result.jobTitle = v; consumed[idx] = "jobTitle"
                add(&result, field: "jobTitle", value: v, confidence: 0.60)
            }
        }

        // 姓名：从「未被任何字段占用」的行里，挑最短、不含数字/符号的一行
        if result.name == nil {
            if let (_, name) = Self.inferName(lines: lines, consumed: consumed) {
                result.name = name
                // 姓名是推断性质，置信度给低
                add(&result, field: "name", value: name, confidence: 0.45)
            }
        }

        return result
    }

    // MARK: - 私有

    private func add(_ result: inout FieldExtractionResult,
                     field: String, value: String, confidence: Double) {
        result.fieldConfidence.append(
            FieldConfidence(fieldName: field, rawValue: value,
                            confidence: confidence, source: .ocr)
        )
    }

    /// 推断姓名：跳过已被占用的行，选一条「短且像人名」的行
    private static func inferName(lines: [String], consumed: [Int: String]) -> (Int, String)? {
        // 姓名特征：长度 2~20，不含数字、@、://、www、路/街/号/大厦/省/市/公司/集团 等强字段词
        let excludedKeywords = ["公司", "集团", "大学", "学院", "研究院", "科技", "科技有限",
                                "总监", "经理", "工程师", "总裁", "教授", "博士",
                                "省", "市", "区", "路", "街", "号", "大厦", "楼", "室",
                                "有限公司", "Ltd", "Inc", "Corp", "Co", "@", "www", "http"]
        for (idx, line) in lines.enumerated() {
            guard consumed[idx] == nil else { continue }
            // 排除含数字（电话/邮编）
            if line.rangeOfCharacter(from: .decimalDigits) != nil { continue }
            // 排除过长（可能是地址/公司全称）
            guard line.count <= 20 else { continue }
            // 排除含强字段关键词的行
            let containsKeyword = excludedKeywords.contains { line.contains($0) }
            if containsKeyword { continue }
            // 中文名 2~4 字，或英文名（首字母大写 + 空格分隔）
            if line.count >= 2 {
                return (idx, line)
            }
        }
        return nil
    }

    // MARK: - 正则抽取

    private static func extractEmail(_ line: String) -> String? {
        let pattern = #"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}"#
        guard let range = line.range(of: pattern, options: .regularExpression) else { return nil }
        return String(line[range])
    }

    private static func extractWebsite(_ line: String) -> String? {
        // 邮箱行不是网址
        guard !line.contains("@") else { return nil }
        // 提取网址主体（www.xxx.com / http(s)://xxx.com / 域名.后缀），忽略标签前缀
        guard let range = line.range(of: #"(?:https?://)?(?:www\.)?[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+"#,
                                     options: .regularExpression) else { return nil }
        var url = String(line[range])
        // 去掉可能残留的行尾标点
        url = url.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:。，；：、"))
        return url
    }

    private static func extractMobile(_ line: String) -> String? {
        // 中国手机号：1[3-9]xxxxxxxxx，允许 +86 / 86 / 空格 / 连字符
        let cnPattern = #"(?:\+?86[\s\-]?)?1[3-9]\d[\s\-]?\d{4}[\s\-]?\d{4}"#
        if let range = line.range(of: cnPattern, options: .regularExpression) { return String(line[range]) }
        // 国际手机号：+1-555-123-4567 这类（+ 号开头，含数字和连字符）
        let intlPattern = #"\+\d{1,3}[\s\-]\d{3}[\s\-]\d{3}[\s\-]\d{4}"#
        if let range = line.range(of: intlPattern, options: .regularExpression) { return String(line[range]) }
        // 纯 "手机/Mobile/Cell" 标签后跟数字（"电话"留给座机）
        let labelPattern = #"(?:手机|Mobile|Cell)[:：\s]+(\d[\d\s\-]{6,})"#
        if let range = line.range(of: labelPattern, options: .regularExpression),
           let numRange = line[range].range(of: #"\d[\d\s\-]{6,}"#, options: .regularExpression) {
            return String(line[range][numRange])
        }
        return nil
    }

    private static func extractOfficePhone(_ line: String) -> String? {
        // 固定电话：0xx-xxxxxxx 或 (0xx) xxxxxxx，且不是手机号
        guard extractMobile(line) == nil else { return nil }
        let pattern = #"(?:\(?0\d{2,3}\)?[\s\-]?)?\d{3,4}[\s\-]\d{7,8}"#
        if let range = line.range(of: pattern, options: .regularExpression) { return String(line[range]) }
        // 带标签的座机：办公/座机/Tel/电话/Office，用捕获组保留完整号码（含括号）
        let labelPattern = #"(?:办公|座机|Tel|电话|Office)[:：\s]+([0-9\s\-()]{7,})"#
        return firstCapture(in: line, pattern: labelPattern)
    }

    /// 传真：仅当带 Fax/传真 标签时识别，避免和座机串号
    private static func extractFax(_ line: String) -> String? {
        let labelPattern = #"(?:Fax|传真)[:：\s]+([0-9\s\-()]{7,})"#
        return firstCapture(in: line, pattern: labelPattern)
    }

    /// 取正则第一个捕获组，用于「带标签」字段，避免丢掉号码里的括号/前缀
    private static func firstCapture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        guard match.numberOfRanges > 1 else { return nil }
        let r = match.range(at: 1)
        guard r.location != NSNotFound else { return nil }
        return ns.substring(with: r)
    }

    private static func extractAddress(_ line: String) -> String? {
        let keywords = ["省", "市", "区", "县", "路", "街", "号", "大厦", "楼", "室",
                        "园", "广场", "中心", "工业区", "新区", "大道",
                        "Street", "Road", "Avenue", "Ave", "Blvd", "Lane",
                        "Drive", "Suite", "Floor", "Building", "District"]
        guard keywords.contains(where: { line.contains($0) }) else { return nil }
        // 地址通常较长，且不含 email/@/http
        guard !line.contains("@"), !line.lowercased().contains("http") else { return nil }
        return line
    }

    private static func extractCompany(_ line: String) -> String? {
        let keywords = ["公司", "集团", "大学", "学院", "研究院", "研究所", "医院",
                        "银行", "事务所", "中心", "有限公司",
                        "Ltd", "Inc", "Corp", "Co.", "LLC", "GmbH", "Co.,Ltd", "Co., Ltd",
                        "Technology", "Technologies", "Labs", "Institute"]
        guard keywords.contains(where: { line.contains($0) }) else { return nil }
        // 排除地址类（含省市路街号）和电话邮箱
        guard !line.contains("@"), extractMobile(line) == nil else { return nil }
        return line
    }

    private static func extractJobTitle(_ line: String) -> String? {
        let keywords = ["总监", "经理", "主管", "工程师", "总裁", "董事长", "总经理",
                        "副总裁", "助理", "顾问", "设计师", "分析师", "研究员", "教授", "博士",
                        "CEO", "CTO", "CFO", "COO", "CMO", "CIO", "VP", "Founder", "Co-Founder",
                        "Manager", "Director", "Engineer", "Developer", "Designer", "Lead"]
        guard keywords.contains(where: { line.contains($0) }) else { return nil }
        guard line.count <= 30 else { return nil }
        return line
    }
}