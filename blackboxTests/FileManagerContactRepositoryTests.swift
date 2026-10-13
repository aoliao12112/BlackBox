import XCTest
@testable import blackbox

final class FileManagerContactRepositoryTests: XCTestCase {
    func testSaveReloadSearchAndDeleteRoundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("blackbox-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let repository = FileManagerContactRepository(baseDirectory: directory)
        var card = BusinessCard.emptyCard()
        card.name = "王小明"
        card.company = "示例科技有限公司"
        card.email = "primary@example.com"
        card.additionalEmails = ["other@example.com"]

        try await repository.save(card)
        let fetched = try await repository.fetchCard(id: card.id)
        let loaded = try XCTUnwrap(fetched)
        XCTAssertEqual(loaded.name, card.name)
        XCTAssertEqual(loaded.additionalEmails, ["other@example.com"])
        let matches = try await repository.search(keyword: "other@example.com")
        XCTAssertEqual(matches.count, 1)

        try await repository.delete(id: card.id)
        let deleted = try await repository.fetchCard(id: card.id)
        XCTAssertNil(deleted)
    }
}
