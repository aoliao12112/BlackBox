import XCTest
@testable import blackbox

final class RuleBasedFieldExtractorTests: XCTestCase {
    private let extractor = RuleBasedFieldExtractor()

    private func extract(_ text: String) async throws -> FieldExtractionResult {
        try await extractor.extractFields(
            from: OCRResult(rawText: text, textBlocks: [], language: nil)
        )
    }

    func testDoesNotGuessSingleBrandWordAsName() async throws {
        let result = try await extract("Apple\napple@example.com")
        XCTAssertNil(result.name)
        XCTAssertEqual(result.email, "apple@example.com")
    }

    func testRecognizesConservativeChineseAndEnglishNames() async throws {
        let chinese = try await extract("王小明")
        let english = try await extract("David Chen")
        XCTAssertEqual(chinese.name, "王小明")
        XCTAssertEqual(english.name, "David Chen")
    }

    func testClassifiesInternationalPhoneLabels() async throws {
        let result = try await extract("Mobile: +86 138 0000 0001\nTel: +86 21-6666-8888\nFax: +86 21-6666-9999")
        XCTAssertEqual(result.mobile, "+86 138 0000 0001")
        XCTAssertEqual(result.officePhone, "+86 21-6666-8888")
        XCTAssertEqual(result.fax, "+86 21-6666-9999")
    }

    func testKeepsAllEmails() async throws {
        let result = try await extract("a@example.com, b@example.com\nc@example.com")
        XCTAssertEqual(result.email, "a@example.com")
        XCTAssertEqual(result.additionalEmails, ["b@example.com", "c@example.com"])
    }

    func testMissingWebsiteRemainsNil() async throws {
        let result = try await extract("李华\n手机：13800000000")
        XCTAssertNil(result.website)
    }
}
