import SwiftUI

struct WelcomeView: View {
    var viewModel: JourneyViewModel

    private var isPreparing: Bool {
        viewModel.journeyStatus == .preparing || viewModel.voiceState == .processing
    }

    var body: some View {
        ZStack {
            IrshadTheme.Colors.appBackgroundGradient
                .ignoresSafeArea()

            if viewModel.hasStartedOnboarding {
                startedExperience
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                introExperience
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .environment(\.layoutDirection, viewModel.layoutDirection)
        .animation(
            IrshadTheme.Animations.resolved(IrshadTheme.Animations.cardReveal, reduceMotion: viewModel.reduceMotionPreferred),
            value: viewModel.hasStartedOnboarding
        )
    }

    private var introExperience: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.height < 680
            let isTight = proxy.size.height < 780

            VStack(spacing: isTight ? IrshadTheme.Layout.spacingStandard : IrshadTheme.Layout.spacingComfortable) {
                introHeader(isCompact: isCompact)

                WelcomeSceneIllustration(
                    isCompact: isCompact,
                    reduceMotion: viewModel.reduceMotionPreferred
                )

                optionPanel(isTight: isTight)

                startButton
            }
            .padding(.horizontal, IrshadTheme.Layout.outerMarginCompact)
            .padding(.vertical, isCompact ? IrshadTheme.Layout.spacingStandard : IrshadTheme.Layout.spacingSection)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .center)
        }
    }

    private var startedExperience: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: IrshadTheme.Layout.spacingSection) {
                    introBrandBar

                    if isPreparing {
                        preparingBanner
                    }

                    AssistantGreetingView(
                        message: viewModel.onboardingGreetingMessage,
                        emoji: viewModel.selectedVoicePersona.assistantEmoji,
                        name: viewModel.selectedVoicePersona.displayName(in: viewModel.currentLanguage),
                        reduceMotion: viewModel.reduceMotionPreferred
                    )

                    BusinessProfileSummaryView(viewModel: viewModel)
                }
                .padding(.horizontal, IrshadTheme.Layout.outerMarginCompact)
                .padding(.top, IrshadTheme.Layout.spacingMajor)
                .padding(.bottom, IrshadTheme.Layout.bottomDockHeight * 3.2)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack {
                Spacer(minLength: 0)
                InputDockView(viewModel: viewModel, isWelcome: true)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }

    private func introHeader(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? IrshadTheme.Layout.spacingTight : IrshadTheme.Layout.spacingStandard) {
            introBrandBar

            VStack(spacing: isCompact ? IrshadTheme.Layout.spacingTight : IrshadTheme.Layout.spacingStandard) {
                Text(introTitle)
                    .font(IrshadTheme.Typography.appFont(size: isCompact ? 32 : 40, weight: .bold, language: viewModel.currentLanguage))
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(introSubtitle)
                    .font(IrshadTheme.Typography.appFont(size: isCompact ? 16 : 18, language: viewModel.currentLanguage))
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 430)
            }
        }
    }

    private var introBrandBar: some View {
        HStack(alignment: .center, spacing: 10) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)

            Text(viewModel.appTitle)
                .font(IrshadTheme.Typography.appFont(size: 34, weight: .bold, language: .en))
                .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .environment(\.layoutDirection, .leftToRight)
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func optionPanel(isTight: Bool) -> some View {
        VStack(spacing: isTight ? IrshadTheme.Layout.spacingStandard : IrshadTheme.Layout.spacingComfortable) {
            OptionSegmentedControl(
                title: personaOptionTitle,
                options: VoicePersona.allCases,
                selection: viewModel.selectedVoicePersona,
                optionTitle: { $0.onboardingTitle },
                optionLeadingText: { $0.assistantEmoji },
                language: viewModel.currentLanguage
            ) { persona in
                viewModel.selectVoicePersona(persona)
            }

            OptionSegmentedControl(
                title: languageOptionTitle,
                options: [.en, .ar],
                selection: viewModel.currentLanguage,
                optionTitle: { $0.onboardingTitle },
                optionLeadingText: { $0.onboardingIcon },
                language: viewModel.currentLanguage
            ) { language in
                viewModel.selectLanguage(language)
            }
        }
        .padding(isTight ? IrshadTheme.Layout.spacingStandard : IrshadTheme.Layout.spacingComfortable)
        .background {
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surface.opacity(0.88))
                .overlay {
                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                }
        }
    }

    private var startButton: some View {
        Button {
            viewModel.beginOnboarding()
        } label: {
            HStack(spacing: IrshadTheme.Layout.spacingStandard) {
                Image(systemName: "arrow.forward")
                    .font(.system(size: 24, weight: .bold))

                Text(startButtonTitle)
                    .font(IrshadTheme.Typography.appFont(size: 22, weight: .semibold, language: viewModel.currentLanguage))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)

                Image(systemName: "mic.fill")
                    .font(.system(size: 22, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, IrshadTheme.Layout.spacingSection)
            .frame(minHeight: 58)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(IrshadTheme.Colors.primaryAccent)
            }
            .irshadShadow(
                IrshadTheme.Shadow(
                    color: IrshadTheme.Colors.primaryAccent.opacity(0.22),
                    radius: 20,
                    x: 0,
                    y: 12
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(startButtonTitle))
    }

    private var preparingBanner: some View {
        HStack(spacing: IrshadTheme.Layout.spacingStandard) {
            ProgressView()
                .tint(IrshadTheme.Colors.primaryAccent)

            Text(preparingMessage)
                .font(IrshadTheme.Typography.secondaryLabelDynamic)
                .foregroundStyle(IrshadTheme.Colors.primaryText)

            Spacer(minLength: 0)
        }
        .padding(IrshadTheme.Layout.spacingComfortable)
        .background {
            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                .fill(IrshadTheme.Colors.surfaceTint)
        }
    }

    private var introTitle: String {
        switch viewModel.currentLanguage {
        case .ar:
            return "ابدأ مشروعك بمحادثة"
        case .en:
            return "Start your business with a conversation"
        }
    }

    private var introSubtitle: String {
        switch viewModel.currentLanguage {
        case .ar:
            return "أجب عن أسئلة صوتية بسيطة، وسنرشدك خطوة بخطوة من الفكرة إلى خطة واضحة."
        case .en:
            return "Answer a few simple voice questions and Irshad will guide you from idea to clear plan."
        }
    }

    private var personaOptionTitle: String {
        switch viewModel.currentLanguage {
        case .ar:
            return "اختر المرشد"
        case .en:
            return "Choose your guide"
        }
    }

    private var languageOptionTitle: String {
        switch viewModel.currentLanguage {
        case .ar:
            return "لغة المحادثة"
        case .en:
            return "Conversation Language"
        }
    }

    private var startButtonTitle: String {
        switch viewModel.currentLanguage {
        case .ar:
            return "ابدأ الآن"
        case .en:
            return "Start now"
        }
    }

    private var preparingMessage: String {
        switch viewModel.currentLanguage {
        case .ar:
            return "نجهز تجربة الصوت"
        case .en:
            return "Preparing voice"
        }
    }
}

private struct AssistantGreetingView: View {
    let message: String
    let emoji: String
    let name: String
    let reduceMotion: Bool

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var isVisible = false
    @State private var isWaving = false
    @State private var isPressed = false

    private var shouldReduceMotion: Bool {
        reduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        VStack(spacing: IrshadTheme.Layout.spacingComfortable) {
            Button {
                playInteraction()
            } label: {
                Text(emoji)
                    .font(.system(size: 76))
                    .scaleEffect(isPressed ? 1.08 : 1)
                    .rotationEffect(.degrees(shouldReduceMotion ? 0 : (isWaving ? 7 : -7)))
                    .opacity(isVisible ? 1 : 0)
                    .frame(width: 104, height: 104)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(name))
            .accessibilityHint(Text("Tap to wave."))

            Text(message)
                .font(IrshadTheme.Typography.primaryBodyDynamic)
                .foregroundStyle(IrshadTheme.Colors.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 500)
        .onAppear {
            withAnimation(.easeOut(duration: 0.32)) {
                isVisible = true
            }

            guard !shouldReduceMotion else {
                return
            }

            isWaving = true
        }
        .animation(
            IrshadTheme.Animations.resolved(
                Animation.easeInOut(duration: 0.85).repeatForever(autoreverses: true),
                reduceMotion: shouldReduceMotion
            ),
            value: isWaving
        )
        .animation(IrshadTheme.Animations.buttonFeedback, value: isPressed)
    }

    private func playInteraction() {
        guard !shouldReduceMotion else {
            return
        }

        isPressed = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            isPressed = false
        }
    }
}

private struct WelcomeSceneIllustration: View {
    let isCompact: Bool
    let reduceMotion: Bool

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var bubbleIsLifted = false

    private var shouldReduceMotion: Bool {
        reduceMotion || accessibilityReduceMotion
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                ZStack(alignment: .bottom) {
                    RollingHill(heightRatio: 0.58)
                        .fill(IrshadTheme.Colors.softHighlight.opacity(0.18))
                        .offset(y: 8)

                    RollingHill(heightRatio: 0.38)
                        .fill(IrshadTheme.Colors.primaryAccent.opacity(0.10))
                        .offset(y: 18)

                    PalmTree()
                        .fill(IrshadTheme.Colors.supportingAccent.opacity(0.32))
                        .frame(width: 62, height: 78)
                        .offset(x: -128, y: -38)

                    House()
                        .fill(IrshadTheme.Colors.primaryAccent.opacity(0.22))
                        .frame(width: 68, height: 54)
                        .offset(x: -64, y: -28)
                }
                .frame(height: isCompact ? 78 : 96)
            }

            floatingSpeechBubble
                .offset(
                    x: bubbleIsLifted && !shouldReduceMotion ? 82 : 88,
                    y: (isCompact ? -28 : -36) + (bubbleIsLifted && !shouldReduceMotion ? -8 : 0)
                )

            Circle()
                .fill(.white.opacity(0.94))
                .frame(width: isCompact ? 118 : 138, height: isCompact ? 118 : 138)
                .overlay {
                    Circle()
                        .stroke(IrshadTheme.Colors.softHighlight.opacity(0.34), lineWidth: 10)
                }
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                }
                .shadow(color: IrshadTheme.Colors.primaryAccent.opacity(0.16), radius: 18, x: 0, y: 12)
                .overlay {
                    Image(systemName: "mic.fill")
                        .font(.system(size: isCompact ? 46 : 54, weight: .semibold))
                        .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                }
                .offset(y: isCompact ? 34 : 44)
        }
        .frame(height: isCompact ? 156 : 184)
        .frame(maxWidth: 420)
        .accessibilityHidden(true)
        .onAppear {
            guard !shouldReduceMotion else {
                return
            }

            bubbleIsLifted = true
        }
        .animation(
            IrshadTheme.Animations.resolved(
                Animation.easeInOut(duration: 2.6).repeatForever(autoreverses: true),
                reduceMotion: shouldReduceMotion
            ),
            value: bubbleIsLifted
        )
    }

    private var floatingSpeechBubble: some View {
        SpeechBubble()
            .fill(.white.opacity(0.94))
            .overlay {
                VoiceBars()
                    .stroke(IrshadTheme.Colors.supportingAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 58, height: 30)
            }
            .overlay {
                SpeechBubble()
                    .stroke(IrshadTheme.Colors.primaryAccent.opacity(0.14), lineWidth: 1)
            }
            .frame(width: 126, height: 72)
            .shadow(color: IrshadTheme.Colors.primaryAccent.opacity(0.08), radius: 12, x: 0, y: 8)
    }
}

private struct RollingHill: Shape {
    let heightRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseY = rect.height
        let startY = rect.height * heightRatio

        path.move(to: CGPoint(x: 0, y: baseY))
        path.addLine(to: CGPoint(x: 0, y: startY))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.45, y: rect.height * (heightRatio - 0.08)),
            control1: CGPoint(x: rect.width * 0.16, y: rect.height * (heightRatio - 0.18)),
            control2: CGPoint(x: rect.width * 0.28, y: rect.height * (heightRatio + 0.10))
        )
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * (heightRatio - 0.03)),
            control1: CGPoint(x: rect.width * 0.65, y: rect.height * (heightRatio - 0.30)),
            control2: CGPoint(x: rect.width * 0.74, y: rect.height * (heightRatio + 0.18))
        )
        path.addLine(to: CGPoint(x: rect.width, y: baseY))
        path.closeSubpath()
        return path
    }
}

private struct PalmTree: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let trunkTop = rect.minY + rect.height * 0.34
        let trunkBottom = rect.maxY

        path.move(to: CGPoint(x: midX - 4, y: trunkBottom))
        path.addLine(to: CGPoint(x: midX + 2, y: trunkTop))
        path.addLine(to: CGPoint(x: midX + 8, y: trunkBottom))
        path.closeSubpath()

        let leaves = [
            (CGPoint(x: midX, y: trunkTop), CGPoint(x: rect.minX, y: rect.minY + 18), CGPoint(x: midX - 7, y: trunkTop + 8)),
            (CGPoint(x: midX, y: trunkTop), CGPoint(x: rect.minX + 8, y: rect.minY), CGPoint(x: midX + 2, y: trunkTop + 6)),
            (CGPoint(x: midX, y: trunkTop), CGPoint(x: rect.maxX - 4, y: rect.minY + 8), CGPoint(x: midX + 5, y: trunkTop + 8)),
            (CGPoint(x: midX, y: trunkTop), CGPoint(x: rect.maxX, y: rect.minY + 30), CGPoint(x: midX + 4, y: trunkTop + 12)),
            (CGPoint(x: midX, y: trunkTop), CGPoint(x: midX + 2, y: rect.minY), CGPoint(x: midX - 6, y: trunkTop + 6))
        ]

        for leaf in leaves {
            path.move(to: leaf.0)
            path.addQuadCurve(to: leaf.1, control: leaf.2)
            path.addQuadCurve(to: leaf.0, control: CGPoint(x: (leaf.1.x + leaf.0.x) / 2, y: leaf.1.y + 12))
        }

        return path
    }
}

private struct House: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let roofPeak = CGPoint(x: rect.midX, y: rect.minY)
        let roofLeft = CGPoint(x: rect.minX + 4, y: rect.minY + rect.height * 0.38)
        let roofRight = CGPoint(x: rect.maxX - 4, y: rect.minY + rect.height * 0.38)
        let bodyTop = rect.minY + rect.height * 0.36

        path.move(to: roofLeft)
        path.addLine(to: roofPeak)
        path.addLine(to: roofRight)
        path.addLine(to: CGPoint(x: rect.maxX - 10, y: bodyTop))
        path.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + 10, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + 10, y: bodyTop))
        path.closeSubpath()

        path.addRect(CGRect(x: rect.midX - 6, y: rect.maxY - 20, width: 12, height: 20))
        return path
    }
}

private struct SpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let bubbleRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height * 0.82)
        path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: 26, height: 26))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.22, y: bubbleRect.maxY - 4))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.34, y: bubbleRect.maxY - 6))
        path.closeSubpath()
        return path
    }
}

private struct VoiceBars: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let bars: [CGFloat] = [0.28, 0.46, 0.70, 0.96, 0.66, 0.44, 0.26]
        let spacing = rect.width / CGFloat(bars.count - 1)

        for (index, height) in bars.enumerated() {
            let x = rect.minX + CGFloat(index) * spacing
            let barHeight = rect.height * height
            path.move(to: CGPoint(x: x, y: rect.midY - barHeight / 2))
            path.addLine(to: CGPoint(x: x, y: rect.midY + barHeight / 2))
        }

        return path
    }
}

private struct OptionSegmentedControl<Option: Hashable>: View {
    let title: String
    let options: [Option]
    let selection: Option
    let optionTitle: (Option) -> String
    let optionLeadingText: (Option) -> String
    let language: AppLanguage
    let select: (Option) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            Text(title)
                .font(IrshadTheme.Typography.appFont(size: 18, weight: .bold, language: language))
                .foregroundStyle(IrshadTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.86)

            HStack(spacing: IrshadTheme.Layout.spacingTight) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == selection

                    Button {
                        select(option)
                    } label: {
                        HStack(spacing: IrshadTheme.Layout.spacingTight) {
                            Text(optionLeadingText(option))
                                .font(.system(size: 20, weight: .semibold))

                            Text(optionTitle(option))
                                .font(IrshadTheme.Typography.appFont(size: 17, weight: .semibold, language: language))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(isSelected ? .white : IrshadTheme.Colors.primaryText)
                        .frame(minHeight: IrshadTheme.Layout.minimumTapTarget)
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? IrshadTheme.Colors.primaryAccent : IrshadTheme.Colors.surfaceTint)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isSelected ? Color.clear : IrshadTheme.Colors.separator, lineWidth: 1)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}

private extension AppLanguage {
    var onboardingTitle: String {
        switch self {
        case .ar:
            return "العربية"
        case .en:
            return "English"
        }
    }

    var onboardingIcon: String {
        switch self {
        case .ar:
            return "ع"
        case .en:
            return "Aa"
        }
    }
}

private extension VoicePersona {
    var onboardingTitle: String {
        switch self {
        case .male:
            return "Ahmad"
        case .female:
            return "Zainab"
        }
    }
}

#Preview {
    WelcomeView(viewModel: AppEnvironment.live.makeJourneyViewModel())
}
