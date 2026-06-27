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

    /// Spacers between each group (instead of a single fixed-spacing stack
    /// centered in the available height) so any extra room on taller screens
    /// gets distributed across the composition instead of piling up as dead
    /// margins at the very top and very bottom.
    private var introExperience: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.height < 680
            let isTight = proxy.size.height < 780

            VStack(spacing: 0) {
                Spacer(minLength: isCompact ? 8 : 14)

                introHeader(isCompact: isCompact)

                Spacer(minLength: isCompact ? 16 : 26)

                AppStoryRow(isCompact: isCompact, reduceMotion: viewModel.reduceMotionPreferred)

                Spacer(minLength: isCompact ? 16 : 26)

                optionPanel(isTight: isTight)

                Spacer(minLength: isCompact ? 14 : 22)

                startButton

                Spacer(minLength: isCompact ? 8 : 14)
            }
            .padding(.horizontal, IrshadTheme.Layout.outerMarginCompact)
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

    /// Brand mark > title > subtitle, in that visual weight order, so the eye
    /// has a single clear entry point instead of competing headlines.
    private func introHeader(isCompact: Bool) -> some View {
        VStack(spacing: IrshadTheme.Layout.spacingTight) {
            introBrandBar

            VStack(spacing: IrshadTheme.Layout.spacingTight) {
                Text(introTitle)
                    .font(IrshadTheme.Typography.appFont(size: isCompact ? 27 : 31, weight: .bold, language: viewModel.currentLanguage))
                    .foregroundStyle(IrshadTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(introSubtitle)
                    .font(IrshadTheme.Typography.appFont(size: isCompact ? 15 : 16, language: viewModel.currentLanguage))
                    .foregroundStyle(IrshadTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 340)
            }
        }
    }

    /// Small, quiet logotype — an identifier, not a headline.
    private var introBrandBar: some View {
        HStack(alignment: .center, spacing: 7) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)

            Text(viewModel.appTitle)
                .font(IrshadTheme.Typography.appFont(size: 18, weight: .semibold, language: .en))
                .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
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
                    .font(.system(size: 22, weight: .bold))

                Text(startButtonTitle)
                    .font(IrshadTheme.Typography.appFont(size: 20, weight: .semibold, language: viewModel.currentLanguage))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)

                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, IrshadTheme.Layout.spacingSection)
            .frame(minHeight: 54)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(IrshadTheme.Colors.primaryAccent)
            }
            .irshadShadow(
                IrshadTheme.Shadow(
                    color: IrshadTheme.Colors.primaryAccent.opacity(0.22),
                    radius: 18,
                    x: 0,
                    y: 10
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
            return "خطّط لتأسيس مشروعك في 10 دقائق"
        case .en:
            return "Plan your business setup in 10 minutes"
        }
    }

    private var introSubtitle: String {
        switch viewModel.currentLanguage {
        case .ar:
            return "أجب بصوتك عن أسئلة بسيطة واحصل على خطة واضحة للخطوات التالية."
        case .en:
            return "Answer a few voice questions and get a clear plan for your next steps." }
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

/// Tells the app's story in three flat, non-tappable-looking icon badges —
/// voice in, a plan out, a business launched — linked by small arrows that
/// nudge gently in the direction of the flow. No shadow/elevation on the
/// badges on purpose: that's what made the old mic circle read as a button.
private struct AppStoryRow: View {
    let isCompact: Bool
    let reduceMotion: Bool

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var isNudged = false

    private var shouldReduceMotion: Bool {
        reduceMotion || accessibilityReduceMotion
    }

    private var iconSize: CGFloat {
        isCompact ? 44 : 50
    }

    var body: some View {
        HStack(spacing: isCompact ? 8 : 12) {
            storyIcon("mic.fill")
            arrowGlyph
            storyIcon("list.bullet.clipboard.fill")
            arrowGlyph
            storyIcon("building.2.fill")
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !shouldReduceMotion else {
                return
            }

            isNudged = true
        }
        .animation(
            IrshadTheme.Animations.resolved(
                Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                reduceMotion: shouldReduceMotion
            ),
            value: isNudged
        )
    }

    private var arrowGlyph: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: isCompact ? 12 : 14, weight: .semibold))
            .foregroundStyle(IrshadTheme.Colors.primaryAccent.opacity(0.45))
            .offset(x: (isNudged && !shouldReduceMotion) ? 3 : -3)
    }

    private func storyIcon(_ systemName: String) -> some View {
        ZStack {
            Circle()
                .fill(IrshadTheme.Colors.primaryAccent.opacity(0.10))

            Image(systemName: systemName)
                .font(.system(size: isCompact ? 17 : 20, weight: .semibold))
                .foregroundStyle(IrshadTheme.Colors.primaryAccent)
        }
        .frame(width: iconSize, height: iconSize)
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
