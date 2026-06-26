import SwiftUI

extension IrshadTheme {
    enum Typography {
        static let largeTitle = bricolage(size: 38, weight: .bold)
        static let sectionTitle = bricolage(size: 26, weight: .semibold)
        static let stepIndicator = bricolage(size: 20, weight: .semibold)
        static let primaryBody = bricolage(size: 18, weight: .regular)
        static let cardTitle = bricolage(size: 19, weight: .semibold)
        static let secondaryLabel = bricolage(size: 15, weight: .regular)
        static let statusMicrocopy = bricolage(size: 14, weight: .medium)

        static let largeTitleCompact = bricolage(size: 34, weight: .bold)
        static let largeTitleExpanded = bricolage(size: 40, weight: .bold)
        static let sectionTitleCompact = bricolage(size: 24, weight: .semibold)
        static let sectionTitleExpanded = bricolage(size: 28, weight: .semibold)
        static let primaryBodyCompact = bricolage(size: 17, weight: .regular)
        static let primaryBodyExpanded = bricolage(size: 19, weight: .regular)

        static func appFont(size: CGFloat, weight: Font.Weight = .regular, language: AppLanguage = .en) -> Font {
            language == .ar ? .system(size: size, weight: weight, design: .default) : bricolage(size: size, weight: weight)
        }

        static func appDynamic(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular, language: AppLanguage = .en) -> Font {
            language == .ar ? .system(textStyle, design: .default).weight(weight) : bricolage(textStyle, weight: weight)
        }

        private static func bricolage(size: CGFloat, weight: Font.Weight) -> Font {
            Font.custom(bricolageName(for: weight), size: size)
        }

        private static func bricolage(_ textStyle: Font.TextStyle, weight: Font.Weight) -> Font {
            Font.custom(bricolageName(for: weight), size: baseSize(for: textStyle), relativeTo: textStyle)
        }

        private static func bricolageName(for weight: Font.Weight) -> String {
            switch weight {
            case .bold, .heavy, .black:
                return "BricolageGrotesque-Bold"
            case .semibold:
                return "BricolageGrotesque-SemiBold"
            case .medium:
                return "BricolageGrotesque-Medium"
            default:
                return "BricolageGrotesque-Regular"
            }
        }

        private static func baseSize(for textStyle: Font.TextStyle) -> CGFloat {
            switch textStyle {
            case .largeTitle:
                return 34
            case .title:
                return 28
            case .title2:
                return 22
            case .title3:
                return 20
            case .headline:
                return 17
            case .subheadline:
                return 15
            case .footnote:
                return 13
            case .caption, .caption2:
                return 12
            default:
                return 17
            }
        }
    }
}
