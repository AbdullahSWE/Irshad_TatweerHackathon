import Foundation

protocol ShareServiceProtocol: Sendable {
    func makeFinalPlanSharePayload(_ plan: FinalPlan, trustFacts: TrustFactBundle) async throws -> SharePayload
    func makeCopySummary(_ plan: FinalPlan, trustFacts: TrustFactBundle) -> String
}

struct ShareService: ShareServiceProtocol {
    init() {}

    func makeFinalPlanSharePayload(_ plan: FinalPlan, trustFacts: TrustFactBundle) async throws -> SharePayload {
        let body = makeCopySummary(plan, trustFacts: trustFacts)

        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ShareError.formattingFailed("Share text was empty.")
        }

        return SharePayload(
            id: UUID().uuidString,
            title: "Irshad Plan",
            body: body,
            url: nil,
            items: [body]
        )
    }

    func makeCopySummary(_ plan: FinalPlan, trustFacts: TrustFactBundle) -> String {
        var sections: [String] = ["Irshad Plan"]

        appendSingleValueSection(
            title: "Next action",
            value: plan.nextAction,
            trustLabel: TrustStatus.guidanceOnly.shareLabel,
            to: &sections
        )

        appendListSection(
            title: "Roadmap",
            items: plan.roadmap.enumerated().map { index, step in
                "\(index + 1). [\(TrustStatus.guidanceOnly.shareLabel)] \(step)"
            },
            to: &sections
        )

        appendSingleValueSection(
            title: "Estimated total cost",
            value: plan.totalEstCost,
            trustLabel: TrustStatus.estimated.shareLabel,
            to: &sections
        )

        appendSingleValueSection(
            title: "Estimated timeline",
            value: plan.totalTimeline,
            trustLabel: TrustStatus.estimated.shareLabel,
            to: &sections
        )

        appendFactSection(title: "Verified facts", facts: trustFacts.verified, to: &sections)
        appendFactSection(title: "Estimated facts", facts: trustFacts.estimated, to: &sections)
        appendUnverifiedSection(plan: plan, trustFacts: trustFacts, to: &sections)
        appendMissingUnknownSection(trustFacts: trustFacts, to: &sections)
        appendGuidanceNote(to: &sections)

        return sections.joined(separator: "\n\n")
    }

    private func appendSingleValueSection(
        title: String,
        value: String?,
        trustLabel: String,
        to sections: inout [String]
    ) {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return
        }

        sections.append("\(title)\n[\(trustLabel)] \(value)")
    }

    private func appendListSection(title: String, items: [String], to sections: inout [String]) {
        let trimmedItems = items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !trimmedItems.isEmpty else {
            return
        }

        sections.append("\(title)\n\(trimmedItems.joined(separator: "\n"))")
    }

    private func appendFactSection(title: String, facts: [TrustFact], to sections: inout [String]) {
        appendListSection(
            title: title,
            items: facts.map(formattedFact(_:)),
            to: &sections
        )
    }

    private func appendUnverifiedSection(
        plan: FinalPlan,
        trustFacts: TrustFactBundle,
        to sections: inout [String]
    ) {
        let planItems = plan.unverified.map {
            "- [\(TrustStatus.unverified.shareLabel)] \($0)"
        }
        let factItems = trustFacts.unverified.map(formattedFact(_:))

        appendListSection(
            title: "Unverified facts",
            items: planItems + factItems,
            to: &sections
        )
    }

    private func appendMissingUnknownSection(trustFacts: TrustFactBundle, to sections: inout [String]) {
        appendListSection(
            title: "Missing or unknown facts",
            items: (trustFacts.missing + trustFacts.unknown).map(formattedFact(_:)),
            to: &sections
        )
    }

    private func appendGuidanceNote(to sections: inout [String]) {
        sections.append(
            """
            Guidance note
            [\(TrustStatus.guidanceOnly.shareLabel)] This plan is guidance only. Verify unverified, missing, unknown, and estimated details with the relevant authority or provider before acting.
            """
        )
    }

    private func formattedFact(_ fact: TrustFact) -> String {
        var text = "- [\(fact.status.shareLabel)] \(fact.label): \(fact.value)"

        if let source = fact.source?.trimmingCharacters(in: .whitespacesAndNewlines), !source.isEmpty {
            text += " (Source: \(source))"
        }

        return text
    }
}

private extension TrustStatus {
    var shareLabel: String {
        switch self {
        case .verified:
            return "Verified"
        case .estimated:
            return "Estimated"
        case .unverified:
            return "Unverified"
        case .missing:
            return "Missing"
        case .unknown:
            return "Unknown"
        case .guidanceOnly:
            return "Guidance only"
        }
    }
}
