import Foundation

struct ActivityArchetype: Sendable {
    let id: String
    let label: String
    let candidateLicenseIds: [String]
    let likelyBankIds: [String]
}

struct AuthorityEntry: Sendable {
    let id: String
    let name: String
    let phone: String?
    let email: String?
    let contactURL: String
    let website: String
}

struct LicenseKBEntry: Sendable {
    let id: String
    let type: String
    let issuer: String
    let authorityId: String
    let bestFor: [String]
    let estCost: String
    let officeRequired: String?
    let approvals: [String]
    let stepSequence: [String]
    let source: String
}

struct BankPlanEntry: Sendable {
    let name: String
    let monthlyFee: String
    let bestFor: String
}

struct BankKBEntry: Sendable {
    let id: String
    let name: String
    let bestFor: [String]
    let plans: [BankPlanEntry]
    let notes: String
    let website: String?
    let phone: String?
    let email: String?
    let source: String
}

final class LocalKnowledgeBase: @unchecked Sendable {
    static let shared = try! LocalKnowledgeBase()

    private enum Stage {
        static let slots: [String: [String]] = [
            "business": ["activity", "businessStage", "operatingModel"],
            "founder": ["founderType", "residency", "hasExistingBusiness", "language"],
            "details": ["location", "jurisdictionPref", "channel", "needsOffice"],
            "budget": ["capital", "expectedRevenue", "employees", "growth"],
            "documents": ["docs", "assets", "permitsHeld"]
        ]
    }

    private let archetypes: [ActivityArchetype]
    private let authorities: [String: AuthorityEntry]
    private let licenses: [String: LicenseKBEntry]
    private let banks: [BankKBEntry]

    init(bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: "knowledge", withExtension: "json") else {
            throw APIError.transport("Bundled knowledge.json was not found.")
        }

        let file = try JSONDecoder().decode(KnowledgeFile.self, from: Data(contentsOf: url))
        var authorityMap: [String: AuthorityEntry] = [:]
        for authority in file.authorities {
            authorityMap[authority.id] = AuthorityEntry(
                id: authority.id,
                name: authority.shortName.map { "\(authority.name) (\($0))" } ?? authority.name,
                phone: authority.phone,
                email: authority.email,
                contactURL: authority.sourceURL ?? authority.servicePlatform ?? authority.mainWebsite ?? "",
                website: (authority.mainWebsite ?? "").withoutHTTPPrefix
            )
        }

        var licenseToArchetypes: [String: [String]] = [:]
        for archetype in file.archetypes {
            for licenseId in archetype.recommendedLicenseIds {
                licenseToArchetypes[licenseId, default: []].append(archetype.id)
            }
        }

        self.authorities = authorityMap
        self.licenses = Dictionary(uniqueKeysWithValues: file.licenses.map { raw in
            let authority = authorityMap[raw.issuingAuthorityId]
            let entry = LicenseKBEntry(
                id: raw.id,
                type: raw.name,
                issuer: authority?.name ?? raw.issuingAuthorityId,
                authorityId: raw.issuingAuthorityId,
                bestFor: raw.bestFor,
                estCost: Self.licenseCostRange(raw.costs),
                officeRequired: Self.officeRequirement(raw.officeRequirement),
                approvals: raw.requiredDocuments,
                stepSequence: raw.stepSequence,
                source: raw.informationSource ?? raw.officialApplicationSource ?? ""
            )
            return (raw.id, entry)
        })
        self.banks = file.banks.map { raw in
            BankKBEntry(
                id: raw.id,
                name: raw.bankName,
                bestFor: raw.bestFor,
                plans: raw.planOptions.map {
                    BankPlanEntry(
                        name: $0.accountName ?? $0.planId ?? "Plan",
                        monthlyFee: $0.monthlyFeeAED.map { "AED \(Self.formatAED($0))/mo" } ?? "see bank",
                        bestFor: $0.bestFor ?? ""
                    )
                },
                notes: raw.notes ?? "",
                website: raw.website,
                phone: Self.firstContactValue(in: raw.contact, matching: ["phone", "contact_centre"]),
                email: Self.firstContactValue(in: raw.contact, matching: ["email"]),
                source: (raw.sourceURL ?? raw.website ?? "").withoutHTTPPrefix
            )
        }
        self.archetypes = file.archetypes.map {
            ActivityArchetype(
                id: $0.id,
                label: $0.name,
                candidateLicenseIds: $0.recommendedLicenseIds,
                likelyBankIds: $0.likelyBankIds
            )
        }
        _ = licenseToArchetypes
    }

    func archetype(id: String) -> ActivityArchetype? {
        archetypes.first { $0.id == id }
    }

    func archetypeList() -> String {
        archetypes.map { "- \($0.id): \($0.label)" }.joined(separator: "\n")
    }

    func stageSlots(_ stage: String) -> [String] {
        Stage.slots[stage] ?? []
    }

    func licenses(for archetypeId: String) -> [LicenseKBEntry] {
        guard let archetype = archetype(id: archetypeId) else { return [] }
        return archetype.candidateLicenseIds.compactMap { licenses[$0] }
    }

    func banks(for archetypeId: String) -> [BankKBEntry] {
        guard let archetype = archetype(id: archetypeId), !archetype.likelyBankIds.isEmpty else {
            return banks
        }
        let ranked = archetype.likelyBankIds.compactMap { id in banks.first { $0.id == id } }
        return ranked.isEmpty ? banks : ranked
    }

    func authority(id: String) -> AuthorityEntry? {
        authorities[id]
    }

    func authorityForFirstLicense(archetypeId: String) -> AuthorityEntry? {
        licenses(for: archetypeId).first.flatMap { authorities[$0.authorityId] }
    }

    func formatLicensesForLLM(archetypeId: String) -> String {
        licenses(for: archetypeId).map { license in
            var lines = [
                "### \(license.type) (issued by \(license.issuer))",
                "- **Estimated cost:** \(license.estCost)",
                "- **Best for:** \(license.bestFor.isEmpty ? "general" : license.bestFor.joined(separator: " · "))"
            ]
            if let officeRequired = license.officeRequired {
                lines.append("- **Office:** \(officeRequired)")
            }
            if !license.approvals.isEmpty {
                lines.append("- **Required documents:** \(license.approvals.joined(separator: ", "))")
            }
            if !license.stepSequence.isEmpty {
                lines.append("- **Steps:** \(license.stepSequence.joined(separator: " -> "))")
            }
            if !license.source.isEmpty {
                lines.append("- **Source:** \(license.source)")
            }
            return lines.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
    }

    func formatBanksForLLM(archetypeId: String) -> String {
        banks(for: archetypeId).map { bank in
            var lines = [
                "### \(bank.name)",
                "- **Best for:** \(bank.bestFor.isEmpty ? "general" : bank.bestFor.joined(separator: " · "))"
            ]
            for plan in bank.plans {
                lines.append("- **\(plan.name)** (\(plan.monthlyFee))\(plan.bestFor.isEmpty ? "" : " - \(plan.bestFor)")")
            }
            if !bank.notes.isEmpty {
                lines.append("- **Notes:** \(bank.notes)")
            }
            if !bank.source.isEmpty {
                lines.append("- **Source:** \(bank.source)")
            }
            return lines.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
    }

    private static func officeRequirement(_ requirement: RawOfficeRequirement?) -> String? {
        guard let officeRequired = requirement?.officeRequired else {
            return nil
        }
        if officeRequired {
            return requirement?.note ?? "Office required"
        }
        return "No office required"
    }

    private static func licenseCostRange(_ costs: RawLicenseCosts?) -> String {
        guard let base = costs?.baseCostAED else {
            return "Verify current fee with authority"
        }
        if let max = costs?.officialMaxRangeAED, max > base {
            return "AED \(formatAED(base)) - \(formatAED(max))"
        }
        return "AED \(formatAED(base))+"
    }

    private static func formatAED(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static func firstContactValue(in contact: [String: JSONValue], matching keys: [String]) -> String? {
        let sortedContact = contact.sorted { $0.key < $1.key }
        for keyFragment in keys {
            if let value = sortedContact.first(where: { $0.key.lowercased().contains(keyFragment) })?.value.displayString,
               !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return nil
    }
}

private extension String {
    var withoutHTTPPrefix: String {
        replacingOccurrences(of: #"^https?://"#, with: "", options: .regularExpression)
    }
}

private struct KnowledgeFile: Decodable {
    let authorities: [RawAuthority]
    let licenses: [RawLicense]
    let banks: [RawBank]
    let archetypes: [RawArchetype]

    private enum CodingKeys: String, CodingKey {
        case authorities
        case licenses
        case banks
        case archetypes
    }
}

private struct RawAuthority: Decodable {
    let id: String
    let name: String
    let shortName: String?
    let phone: String?
    let email: String?
    let mainWebsite: String?
    let servicePlatform: String?
    let sourceURL: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName = "short_name"
        case phone
        case email
        case mainWebsite = "main_website"
        case servicePlatform = "service_platform"
        case sourceURL = "source_url"
    }
}

private struct RawLicenseCosts: Decodable {
    let baseCostAED: Int?
    let officialMaxRangeAED: Int?

    private enum CodingKeys: String, CodingKey {
        case baseCostAED = "base_cost_aed"
        case officialMaxRangeAED = "official_max_range_aed"
    }
}

private struct RawOfficeRequirement: Decodable {
    let officeRequired: Bool?
    let note: String?

    private enum CodingKeys: String, CodingKey {
        case officeRequired = "office_required"
        case note
    }
}

private struct RawLicense: Decodable {
    let id: String
    let name: String
    let issuingAuthorityId: String
    let bestFor: [String]
    let informationSource: String?
    let officialApplicationSource: String?
    let costs: RawLicenseCosts?
    let officeRequirement: RawOfficeRequirement?
    let requiredDocuments: [String]
    let stepSequence: [String]

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case issuingAuthorityId = "issuing_authority_id"
        case bestFor = "best_for"
        case informationSource = "information_source"
        case officialApplicationSource = "official_application_source"
        case costs
        case officeRequirement = "office_requirement"
        case requiredDocuments = "required_documents"
        case stepSequence = "step_sequence"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        issuingAuthorityId = try container.decode(String.self, forKey: .issuingAuthorityId)
        bestFor = try container.decodeIfPresent([String].self, forKey: .bestFor) ?? []
        informationSource = try container.decodeIfPresent(String.self, forKey: .informationSource)
        officialApplicationSource = try container.decodeIfPresent(String.self, forKey: .officialApplicationSource)
        costs = try container.decodeIfPresent(RawLicenseCosts.self, forKey: .costs)
        officeRequirement = try container.decodeIfPresent(RawOfficeRequirement.self, forKey: .officeRequirement)
        requiredDocuments = try container.decodeIfPresent([String].self, forKey: .requiredDocuments) ?? []
        stepSequence = try container.decodeIfPresent([String].self, forKey: .stepSequence) ?? []
    }
}

private struct RawBankPlan: Decodable {
    let planId: String?
    let accountName: String?
    let monthlyFeeAED: Int?
    let bestFor: String?

    private enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case accountName = "account_name"
        case monthlyFeeAED = "monthly_fee_aed"
        case bestFor = "best_for"
    }
}

private struct RawBank: Decodable {
    let id: String
    let bankName: String
    let bestFor: [String]
    let website: String?
    let sourceURL: String?
    let contact: [String: JSONValue]
    let planOptions: [RawBankPlan]
    let notes: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case bankName = "bank_name"
        case bestFor = "best_for"
        case website
        case sourceURL = "source_url"
        case contact
        case planOptions = "plan_options"
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        bankName = try container.decode(String.self, forKey: .bankName)
        bestFor = try container.decodeIfPresent([String].self, forKey: .bestFor) ?? []
        website = try container.decodeIfPresent(String.self, forKey: .website)
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        contact = try container.decodeIfPresent([String: JSONValue].self, forKey: .contact) ?? [:]
        planOptions = try container.decodeIfPresent([RawBankPlan].self, forKey: .planOptions) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

private struct RawArchetype: Decodable {
    let id: String
    let name: String
    let recommendedLicenseIds: [String]
    let likelyBankIds: [String]

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case recommendedLicenseIds = "recommended_license_ids"
        case likelyBankIds = "likely_bank_ids"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        recommendedLicenseIds = try container.decodeIfPresent([String].self, forKey: .recommendedLicenseIds) ?? []
        likelyBankIds = try container.decodeIfPresent([String].self, forKey: .likelyBankIds) ?? []
    }
}
