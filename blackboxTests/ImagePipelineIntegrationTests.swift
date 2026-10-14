import UIKit
import XCTest
@testable import blackbox

@MainActor
final class ImagePipelineIntegrationTests: XCTestCase {
    private func makeSyntheticCardImage() -> UIImage {
        let size = CGSize(width: 1200, height: 800)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor(white: 0.25, alpha: 1).setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: size))

            let cardRect = CGRect(x: 120, y: 130, width: 960, height: 540)
            UIColor.white.setFill()
            context.cgContext.fill(cardRect)
            UIColor.black.setStroke()
            context.cgContext.setLineWidth(8)
            context.cgContext.stroke(cardRect)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 72, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            "BLACKBOX 12345".draw(at: CGPoint(x: 230, y: 320), withAttributes: attributes)
        }
    }

    func testJPEGImportBoundaryDetectionAndPerspectiveCorrection() async throws {
        let source = makeSyntheticCardImage()
        let jpeg = try XCTUnwrap(source.jpegData(compressionQuality: 0.9))
        let imported = try XCTUnwrap(UIImage(data: jpeg))
        let service = RealCardBoundaryService()

        let detected = try await service.detectCardBoundary(in: imported)
        XCTAssertEqual(detected?.count, 4)

        let corrected = try await service.rectifyImage(imported, withCorners: [
            CGPoint(x: 120, y: 130), CGPoint(x: 1080, y: 130),
            CGPoint(x: 1080, y: 670), CGPoint(x: 120, y: 670)
        ])
        XCTAssertGreaterThan(corrected.size.width, 800)
        XCTAssertGreaterThan(corrected.size.height, 400)
        XCTAssertNotNil(corrected.jpegData(compressionQuality: 0.8))
    }

    func testVisionOCRReadsTextFromImportedImage() async throws {
        let source = makeSyntheticCardImage()
        let jpeg = try XCTUnwrap(source.jpegData(compressionQuality: 0.95))
        let imported = try XCTUnwrap(UIImage(data: jpeg))

        let result = try await RealOCRService().recognizeText(from: imported)
        let normalized = result.rawText.uppercased().replacingOccurrences(of: " ", with: "")
        XCTAssertTrue(normalized.contains("BLACKBOX"), result.rawText)
        XCTAssertTrue(normalized.contains("12345"), result.rawText)
        XCTAssertFalse(result.textBlocks.isEmpty)
    }
}
