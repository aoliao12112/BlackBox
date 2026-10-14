import Contacts
import Foundation

/// 将业务模型转换成系统通讯录对象。保持为纯函数，便于单元测试字段映射。
enum ContactBuilder {
    static func build(from card: BusinessCard) -> CNMutableContact {
        let trim = { (value: String?) -> String? in
            value?.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let contact = CNMutableContact()
        if let name = trim(card.name), !name.isEmpty { contact.givenName = name }
        if let company = trim(card.company), !company.isEmpty { contact.organizationName = company }
        if let title = trim(card.jobTitle), !title.isEmpty { contact.jobTitle = title }

        var phones: [CNLabeledValue<CNPhoneNumber>] = []
        if let mobile = trim(card.mobile), !mobile.isEmpty {
            phones.append(.init(label: CNLabelPhoneNumberMobile,
                                value: CNPhoneNumber(stringValue: mobile)))
        }
        if let office = trim(card.officePhone), !office.isEmpty {
            phones.append(.init(label: CNLabelPhoneNumberMain,
                                value: CNPhoneNumber(stringValue: office)))
        }
        if let fax = trim(card.fax), !fax.isEmpty {
            phones.append(.init(label: CNLabelPhoneNumberOtherFax,
                                value: CNPhoneNumber(stringValue: fax)))
        }
        contact.phoneNumbers = phones

        var emails: [CNLabeledValue<NSString>] = []
        for email in [card.email].compactMap({ trim($0) }) + (card.additionalEmails ?? []).compactMap({ trim($0) })
            where !email.isEmpty {
            emails.append(.init(label: CNLabelWork, value: email as NSString))
        }
        contact.emailAddresses = emails

        if let website = trim(card.website), !website.isEmpty {
            contact.urlAddresses = [.init(label: CNLabelWork, value: website as NSString)]
        }
        if let address = trim(card.address), !address.isEmpty {
            let postal = CNMutablePostalAddress()
            postal.street = address
            postal.postalCode = trim(card.postalCode) ?? ""
            contact.postalAddresses = [.init(label: CNLabelWork, value: postal)]
        }
        if let note = trim(card.notes), !note.isEmpty { contact.note = note }
        return contact
    }
}

enum ContactStoreService {
    static func requestAccess(using store: CNContactStore = CNContactStore()) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            store.requestAccess(for: .contacts) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    static func save(_ contact: CNMutableContact,
                     using store: CNContactStore = CNContactStore()) throws {
        let request = CNSaveRequest()
        request.add(contact, toContainerWithIdentifier: nil)
        try store.execute(request)
    }
}
