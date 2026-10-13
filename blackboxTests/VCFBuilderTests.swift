import XCTest
@testable import blackbox

final class VCFBuilderTests: XCTestCase {
    func testVCFContainsAllMappedFieldsAndEmails() {
        var card = BusinessCard.emptyCard()
        card.name = "王小明"
        card.company = "示例科技有限公司"
        card.mobile = "+86 138-0000-0001"
        card.email = "primary@example.com"
        card.additionalEmails = ["second@example.com"]
        card.website = "https://example.com"
        card.address = "上海市杨浦区示例路 1 号"
        card.postalCode = "200000"

        let vcf = VCFBuilder.build(from: card)

        XCTAssertTrue(vcf.contains("FN:王小明"))
        XCTAssertTrue(vcf.contains("TEL;TYPE=CELL:+86 138-0000-0001"))
        XCTAssertTrue(vcf.contains("EMAIL:primary@example.com"))
        XCTAssertTrue(vcf.contains("EMAIL:second@example.com"))
        XCTAssertTrue(vcf.contains("URL:https://example.com"))
        XCTAssertTrue(vcf.contains("ADR;TYPE=WORK:;;上海市杨浦区示例路 1 号;;;200000;"))
    }
}
