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
        VStack(spacing: isCompact ? IrshadTheme.Layout.spacingStandard : IrshadTheme.Layout.spacingComfortable) {
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
        HStack(alignment: .center, spacing: IrshadTheme.Layout.spacingStandard) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            Text(viewModel.appTitle)
                .font(IrshadTheme.Typography.appFont(size: 34, weight: .bold, language: .en))
                .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
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
                    .fill(
                        LinearGradient(
                            colors: [
                                IrshadTheme.Colors.primaryAccent,
                                IrshadTheme.Colors.supportingAccent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
            return "Ali"
        case .female:
            return "Zainab"
        }
    }
}

#Preview {
    WelcomeView(viewModel: AppEnvironment.live.makeJourneyViewModel())
}
