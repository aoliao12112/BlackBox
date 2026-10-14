import AVFoundation
import Contacts
import XCTest
@testable import blackbox

final class PermissionAndContactIntegrationTests: XCTestCase {
    func testGeneratedInfoPlistContainsRequiredPrivacyDescriptions() throws {
        let info = try XCTUnwrap(Bundle.main.infoDictionary)
        for key in [
            "NSCameraUsageDescription",
            "NSPhotoLibraryUsageDescription",
            "NSContactsUsageDescription"
        ] {
            let value = try XCTUnwrap(info[key] as? String, "Missing \(key)")
            XCTAssertFalse(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @MainActor
    func testCameraAuthorizationCanBeGrantedInSimulator() async {
        let manager = CameraManager()
        await manager.requestAuthorization()
        XCTAssertEqual(manager.authorizationStatus, .authorized)
        XCTAssertTrue(manager.isAuthorized)
    }

    func testWriteReadAndDeleteContactInSimulatorStore() async throws {
        let store = CNContactStore()
        let granted = try await ContactStoreService.requestAccess(using: store)
        XCTAssertTrue(granted)
        XCTAssertEqual(CNContactStore.authorizationStatus(for: .contacts), .authorized)

        let marker = "BlackBoxCI\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        var card = BusinessCard.emptyCard()
        card.name = marker
        card.company = "BlackBox Test Company"
        card.jobTitle = "Test Engineer"
        card.mobile = "+86 138-0000-9999"
        card.officePhone = "+86 21-6666-9999"
        card.email = "primary@blackbox.example"
        card.additionalEmails = ["secondary@blackbox.example"]
        card.website = "https://blackbox.example"
        card.address = "上海市测试路 1 号"
        card.postalCode = "200000"

        let contact = ContactBuilder.build(from: card)
        try ContactStoreService.save(contact, using: store)

        let keys: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactJobTitleKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactUrlAddressesKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor
        ]
        let matches = try store.unifiedContacts(
            matching: CNContact.predicateForContacts(matchingName: marker),
            keysToFetch: keys
        )
        let saved = try XCTUnwrap(matches.first(where: { $0.givenName == marker }))

        XCTAssertEqual(saved.organizationName, card.company)
        XCTAssertEqual(saved.jobTitle, card.jobTitle)
        XCTAssertEqual(saved.phoneNumbers.count, 2)
        XCTAssertEqual(saved.emailAddresses.map { $0.value as String }.sorted(),
                       ["primary@blackbox.example", "secondary@blackbox.example"])
        XCTAssertEqual(saved.urlAddresses.first?.value as String?, card.website)
        XCTAssertEqual(saved.postalAddresses.first?.value.street, card.address)
        XCTAssertEqual(saved.postalAddresses.first?.value.postalCode, card.postalCode)

        let cleanup = CNSaveRequest()
        cleanup.delete(try XCTUnwrap(saved.mutableCopy() as? CNMutableContact))
        try store.execute(cleanup)
        let remaining = try store.unifiedContacts(
            matching: CNContact.predicateForContacts(matchingName: marker),
            keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor]
        )
        XCTAssertTrue(remaining.isEmpty)
    }
}
