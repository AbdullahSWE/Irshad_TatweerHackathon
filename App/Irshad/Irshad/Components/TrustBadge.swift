import SwiftUI

struct TrustBadge: View {
    let status: TrustStatus

    init(status: TrustStatus) {
        self.status = status
    }

    var body: some View {
        StatusPill(
            configuration.label,
            systemImage: configuration.systemImage,
            tone: configuration.tone
        )
        .accessibilityValue(Text(configuration.accessibilityValue))
    }

    private var configuration: Configuration {
        switch status {
        case .verified:
            Configuration(
                label: "Verified",
                systemImage: "checkmark.seal.fill",
                tone: .success,
                accessibilityValue: "Verified information"
            )
        case .estimated:
            Configuration(
                label: "Estimated",
                systemImage: "chart.line.uptrend.xyaxis",
                tone: .active,
                accessibilityValue: "Estimated information"
            )
        case .unverified:
            Configuration(
                label: "Unverified",
                systemImage: "exclamationmark.triangle.fill",
                tone: .warning,
                accessibilityValue: "Unverified information"
            )
        case .missing:
            Configuration(
                label: "Missing",
                systemImage: "questionmark.circle.fill",
                tone: .error,
                accessibilityValue: "Missing information"
            )
        case .unknown:
            Configuration(
                label: "Unknown",
                systemImage: "circle.dashed",
                tone: .neutral,
                accessibilityValue: "Unknown information status"
            )
        case .guidanceOnly:
            Configuration(
                label: "Guidance only",
                systemImage: "lightbulb.fill",
                tone: .secondary,
                accessibilityValue: "Guidance only, not verified information"
            )
        }
    }
}

private struct Configuration {
    let label: String
    let systemImage: String
    let tone: StatusPill.Tone
    let accessibilityValue: String
}
