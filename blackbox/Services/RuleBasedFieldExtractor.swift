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
            email: nil, additionalEmails: [], website: nil, address: nil,
            fieldConfidence: []
        )

        // 记录某一行已被哪个字段占用，避免重复抽取（姓名排除法用）
        var consumed: [Int: String] = [:]

        for (idx, line) in lines.enumerated() {
            // 优先级：显式标签 > email > website > 传真 > mobile > officePhone > 地址 > 公司 > 职位
            if consumed[idx] != nil { continue }

            // 显式标签（「公司：」「Mobile:」等）优先于内容启发式：
            // 既能定位无后缀关键词的公司名（Pioneer Marketing Group），
            // 也能避免「成都市…有限公司」被地址规则误抢。
            if let labeled = Self.splitLabel(line),
               consumeLabeled(field: labeled.field, value: labeled.value, index: idx,
                              result: &result, consumed: &consumed) {
                continue
            }

            let emails = Self.extractEmails(line)
            if !emails.isEmpty {
                for value in emails where value != result.email && !result.additionalEmails.contains(value) {
                    if result.email == nil {
                        result.email = value
                        add(&result, field: "email", value: value, confidence: 0.95)
                    } else {
                        result.additionalEmails.append(value)
                        add(&result, field: "additionalEmail", value: value, confidence: 0.95)
                    }
                }
                consumed[idx] = "email"
            } else if result.website == nil, let v = Self.extractWebsite(line) {
                result.website = v; consumed[idx] = "website"
                add(&result, field: "website", value: v, confidence: 0.90)
            } else if result.fax == nil, let v = Self.extractFax(line) {
                result.fax = v; consumed[idx] = "fax"
                add(&result, field: "fax", value: v, confidence: 0.85)
            } else if result.mobile == nil, let v = Self.extractMobile(line) {
                result.mobile = v; consumed[idx] = "mobile"
                add(&result, field: "mobile", value: v, confidence: 0.92)
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

        // 姓名仅接受明确的人名形态；不能把 Apple 等单个品牌词猜成人名。
        if result.name == nil {
            if let (_, name) = Self.inferName(lines: lines, consumed: consumed) {
                let normalized = Self.normalizeName(name)
                result.name = normalized
                add(&result, field: "name", value: normalized, confidence: 0.75)
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

    /// 保守识别人名：2~4 个纯汉字，或 2~4 个首字母大写的英文单词。
    private static func inferName(lines: [String], consumed: [Int: String]) -> (Int, String)? {
        let excludedKeywords = ["公司", "集团", "大学", "学院", "研究院", "科技", "科技有限",
                                "总监", "经理", "工程师", "总裁", "教授", "博士",
                                "省", "市", "区", "路", "街", "号", "大厦", "楼", "室",
                                "有限公司", "Ltd", "Inc", "Corp", "Co", "@", "www", "http"]
        for (idx, line) in lines.enumerated() {
            guard consumed[idx] == nil else { continue }
            if line.rangeOfCharacter(from: .decimalDigits) != nil { continue }
            guard line.count <= 40 else { continue }
            let containsKeyword = excludedKeywords.contains {
                line.range(of: $0, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
            if containsKeyword { continue }
            let chineseName = line.range(of: #"^[\p{Han}]{2,4}$"#, options: .regularExpression) != nil
            let englishName = line.range(
                of: #"^[A-Z][A-Za-z'’-]+(?:\s+[A-Z][A-Za-z'’-]+){1,3}$"#,
                options: .regularExpression
            ) != nil
            // 中英双语姓名：汉字 + 括号内英文，允许全/半角括号且英文大小写不限
            let bilingualName = line.range(
                of: #"^[\p{Han}]{2,4}\s*[（(][A-Za-z][A-Za-z'’-]*(?:\s+[A-Za-z][A-Za-z'’-]*){0,3}[）)]$"#,
                options: [.regularExpression, .caseInsensitive]
            ) != nil
            if chineseName || englishName || bilingualName {
                return (idx, line)
            }
        }
        return nil
    }

    // MARK: - 显式标签

    /// 显式标签 → 字段映射；名片上的标签比内容启发式更可靠
    private static let labeledFields: [(label: String, field: String)] = [
        ("姓名", "name"), ("名字", "name"), ("Name", "name"),
        ("公司", "company"), ("单位", "company"), ("Company", "company"),
        ("职位", "jobTitle"), ("职务", "jobTitle"), ("Title", "jobTitle"),
        ("部门", "ignored"), ("Dept", "ignored"), ("Department", "ignored"),
        ("手机", "mobile"), ("Mobile", "mobile"), ("Cell", "mobile"),
        ("办公", "officePhone"), ("座机", "officePhone"), ("电话", "officePhone"),
        ("Tel", "officePhone"), ("Telephone", "officePhone"),
        ("传真", "fax"), ("Fax", "fax"),
        ("邮箱", "email"), ("电子邮箱", "email"), ("Email", "email"), ("E-mail", "email"),
        ("网址", "website"), ("网站", "website"), ("Web", "website"), ("Website", "website"), ("URL", "website"),
        ("地址", "address"), ("Addr", "address"), ("Address", "address"),
        ("邮编", "ignored"), ("ZIP", "ignored"), ("PostalCode", "ignored"),
    ]

    /// 解析「标签: 值」形式，返回字段名与值；无标签返回 nil
    private static func splitLabel(_ line: String) -> (field: String, value: String)? {
        let ns = line as NSString
        for (label, field) in labeledFields {
            let escaped = NSRegularExpression.escapedPattern(for: label)
            let pattern = "^\\s*\(escaped)\\s*[:：]\\s*(.*)$"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
                  let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)),
                  match.numberOfRanges > 1 else { continue }
            let range = match.range(at: 1)
            guard range.location != NSNotFound else { return (field, "") }
            let value = ns.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
            return (field, value)
        }
        return nil
    }

    /// 按显式标签落位字段；字段已占位或值缺失时返回 false，交回内容启发式
    private func consumeLabeled(field: String, value: String, index: Int,
                                result: inout FieldExtractionResult, consumed: inout [Int: String]) -> Bool {
        if field == "ignored" { consumed[index] = field; return true }
        guard !value.isEmpty else { return false }

        switch field {
        case "name":
            guard result.name == nil else { return false }
            let normalized = Self.normalizeName(value)
            result.name = normalized; consumed[index] = field
            add(&result, field: "name", value: normalized, confidence: 0.90)
        case "company":
            guard result.company == nil else { return false }
            result.company = value; consumed[index] = field
            add(&result, field: "company", value: value, confidence: 0.90)
        case "jobTitle":
            guard result.jobTitle == nil else { return false }
            result.jobTitle = value; consumed[index] = field
            add(&result, field: "jobTitle", value: value, confidence: 0.75)
        case "mobile":
            guard result.mobile == nil else { return false }
            result.mobile = value; consumed[index] = field
            add(&result, field: "mobile", value: value, confidence: 0.95)
        case "officePhone":
            guard result.officePhone == nil else { return false }
            result.officePhone = value; consumed[index] = field
            add(&result, field: "officePhone", value: value, confidence: 0.90)
        case "fax":
            guard result.fax == nil else { return false }
            result.fax = value; consumed[index] = field
            add(&result, field: "fax", value: value, confidence: 0.90)
        case "website":
            guard result.website == nil else { return false }
            result.website = value; consumed[index] = field
            add(&result, field: "website", value: value, confidence: 0.90)
        case "address":
            guard result.address == nil else { return false }
            result.address = value; consumed[index] = field
            add(&result, field: "address", value: value, confidence: 0.80)
        case "email":
            let emails = Self.extractEmails(value)
            guard !emails.isEmpty else { return false }
            for v in emails where v != result.email && !result.additionalEmails.contains(v) {
                if result.email == nil {
                    result.email = v; add(&result, field: "email", value: v, confidence: 0.95)
                } else {
                    result.additionalEmails.append(v); add(&result, field: "additionalEmail", value: v, confidence: 0.95)
                }
            }
            consumed[index] = field
        default:
            return false
        }
        return true
    }

    /// 归一化姓名里的全角括号，便于与标准写法比较
    private static func normalizeName(_ value: String) -> String {
        value
            .replacingOccurrences(of: "（", with: "(")
            .replacingOccurrences(of: "）", with: ")")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - 正则抽取

    private static func extractEmails(_ line: String) -> [String] {
        let pattern = #"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = line as NSString
        return regex.matches(in: line, range: NSRange(location: 0, length: ns.length))
            .map { ns.substring(with: $0.range) }
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
        // 国际号码只有在明确标注 Mobile/Cell/手机时才归为手机，避免误判座机。
        let labelPattern = #"(?i)(?:手机|Mobile|Cell)[:：\s]+(\+?[0-9][0-9\s\-()]{6,}[0-9])"#
        if let value = firstCapture(in: line, pattern: labelPattern) {
            return value.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private static func extractOfficePhone(_ line: String) -> String? {
        // 固定电话：支持 +86 21-6666-8888、021-66668888 等常见格式。
        guard extractMobile(line) == nil else { return nil }
        let labelPattern = #"(?i)(?:办公|座机|Tel|电话|Office)[:：\s]+(\+?[0-9][0-9\s\-()]{6,}[0-9])"#
        if let value = firstCapture(in: line, pattern: labelPattern) {
            return value.trimmingCharacters(in: .whitespaces)
        }
        let pattern = #"(?:\+?\d{1,3}[\s\-])?(?:\(?0?\d{2,3}\)?[\s\-])\d{3,4}[\s\-]?\d{4}"#
        guard let range = line.range(of: pattern, options: .regularExpression) else { return nil }
        return String(line[range])
    }

    /// 传真：仅当带 Fax/传真 标签时识别，避免和座机串号
    private static func extractFax(_ line: String) -> String? {
        let labelPattern = #"(?i)(?:Fax|传真)[:：\s]+(\+?[0-9][0-9\s\-()]{6,}[0-9])"#
        return firstCapture(in: line, pattern: labelPattern)?.trimmingCharacters(in: .whitespaces)
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
