//
//  ExportView.swift
//  blackbox
//
//  Week 5 · 导出页 — 生成并共享 vCard (VCF)
//  Spec: spec.md P10 导出
//

import SwiftUI
import Contacts

// MARK: - VCF 生成器

enum VCFBuilder {
    static func build(from card: BusinessCard) -> String {
        var lines = ["BEGIN:VCARD", "VERSION:3.0"]

        if let name = card.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            lines.append("FN:\(escape(name))")
            lines.append("N:\(escape(name));;;;")
        }
        if let org = card.company, !org.isEmpty { lines.append("ORG:\(escape(org))") }
        if let title = card.jobTitle, !title.isEmpty { lines.append("TITLE:\(escape(title))") }
        if let mobile = card.mobile, !mobile.isEmpty { lines.append("TEL;TYPE=CELL:\(escape(mobile))") }
        if let office = card.officePhone, !office.isEmpty { lines.append("TEL;TYPE=WORK:\(escape(office))") }
        if let fax = card.fax, !fax.isEmpty { lines.append("TEL;TYPE=FAX:\(escape(fax))") }
        if let email = card.email, !email.isEmpty { lines.append("EMAIL:\(escape(email))") }
        for email in card.additionalEmails ?? [] where !email.isEmpty {
            lines.append("EMAIL:\(escape(email))")
        }
        if let web = card.website, !web.isEmpty { lines.append("URL:\(escape(web))") }
        if let addr = card.address, !addr.isEmpty {
            let postal = card.postalCode.map(escape) ?? ""
            lines.append("ADR;TYPE=WORK:;;\(escape(addr));;;\(postal);")
        }
        if let notes = card.notes, !notes.isEmpty { lines.append("NOTE:\(escape(notes))") }

        lines.append("END:VCARD")
        return lines.joined(separator: "\r\n")
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: ",", with: "\\,")
         .replacingOccurrences(of: ";", with: "\\;")
         .replacingOccurrences(of: "\n", with: "\\n")
    }
}

// MARK: - 导出页

struct ExportView: View {

    @EnvironmentObject private var router: Router
    let card: BusinessCard

    @State private var fileURL: URL?
    @State private var saveMessage: String?

    private var vcf: String { VCFBuilder.build(from: card) }

    var body: some View {
        VStack(spacing: 16) {
            Text("名片将导出为 vCard（.vcf）文件")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView {
                Text(vcf)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if let fileURL {
                ShareLink(item: fileURL) {
                    Label("共享 VCF 文件", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            Button {
                saveToContacts()
            } label: {
                Label("保存到系统通讯录", systemImage: "person.crop.circle.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle("导出")
        .navigationBarTitleDisplayMode(.inline)
        .alert("提示", isPresented: Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )) {
            Button("好", role: .cancel) { saveMessage = nil }
        } message: {
            Text(saveMessage ?? "")
        }
        .task { fileURL = writeVCF() }
    }

    private func writeVCF() -> URL? {
        let raw = card.name ?? "card"
        let safe = raw.replacingOccurrences(of: "/", with: "_")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safe).vcf")
        do {
            try vcf.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            saveMessage = "生成 VCF 文件失败：\(error.localizedDescription)"
            return nil
        }
    }

    /// 保存到系统通讯录（T19），需要用户授权
    private func saveToContacts() {
        let contact = ContactBuilder.build(from: card)
        let store = CNContactStore()
        Task {
            do {
                guard try await ContactStoreService.requestAccess(using: store) else {
                    saveMessage = "未获得通讯录权限，请在设置中开启"
                    return
                }
                try ContactStoreService.save(contact, using: store)
                saveMessage = "已保存到系统通讯录"
            } catch {
                saveMessage = "保存失败：\(error.localizedDescription)"
            }
        }
    }
}
