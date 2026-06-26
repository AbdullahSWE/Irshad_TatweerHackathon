import SwiftUI

struct WelcomeView: View {
    var viewModel: JourneyViewModel

    private let examplePrompts = [
        "أريد فتح مقهى مختص في دبي",
        "لدي تطبيق تعليمي وأحتاج خطة ترخيص",
        "أبيع منتجات منزلية وأريد بدء التجارة"
    ]

    private var promiseText: String {
        viewModel.currentPrompt ?? "تحدث عن فكرتك، وسنرشدك خطوة بخطوة"
    }

    private var isPreparing: Bool {
        viewModel.journeyStatus == .preparing || viewModel.voiceState == .processing
    }

    var body: some View {
        ZStack {
            IrshadTheme.Colors.appBackgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: IrshadTheme.Layout.spacingMajor) {
                    header

                    if isPreparing {
                        preparingBanner
                    }

                    BusinessProfileSummaryView(viewModel: viewModel)

                    promptExamples
                }
                .padding(.horizontal, IrshadTheme.Layout.outerMarginCompact)
                .padding(.top, IrshadTheme.Layout.spacingMajor)
                .padding(.bottom, IrshadTheme.Layout.bottomDockHeight * 3.2)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .environment(\.layoutDirection, viewModel.layoutDirection)

            VStack {
                Spacer(minLength: 0)
                InputDockView(viewModel: viewModel, isWelcome: viewModel.journeyStatus == .empty || viewModel.journeyStatus == .preparing)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }

    private var header: some View {
        VStack(spacing: IrshadTheme.Layout.spacingComfortable) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 74, height: 74)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .irshadShadow(IrshadTheme.Shadows.ambientBlueShadow)

            Text(viewModel.appTitle)
                .font(IrshadTheme.Typography.largeTitleDynamic)
                .foregroundStyle(IrshadTheme.Colors.primaryText)
                .multilineTextAlignment(.center)

            Text(promiseText)
                .font(IrshadTheme.Typography.primaryBodyDynamic)
                .foregroundStyle(IrshadTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 420)
        }
        .padding(.top, IrshadTheme.Layout.spacingComfortable)
    }

    private var preparingBanner: some View {
        HStack(spacing: IrshadTheme.Layout.spacingStandard) {
            ProgressView()
                .tint(IrshadTheme.Colors.primaryAccent)

            Text("نجهز تجربة الصوت")
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

    private var promptExamples: some View {
        VStack(alignment: .leading, spacing: IrshadTheme.Layout.spacingStandard) {
            Text("أمثلة سريعة")
                .font(IrshadTheme.Typography.statusMicrocopyDynamic)
                .foregroundStyle(IrshadTheme.Colors.secondaryText)

            VStack(spacing: IrshadTheme.Layout.spacingStandard) {
                ForEach(examplePrompts, id: \.self) { prompt in
                    Button {
                        viewModel.updateTextFallback(prompt)
                    } label: {
                        HStack(spacing: IrshadTheme.Layout.spacingStandard) {
                            Image(systemName: "sparkle.magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(IrshadTheme.Colors.primaryAccent)
                                .frame(width: IrshadTheme.Layout.minimumTapTarget, height: IrshadTheme.Layout.minimumTapTarget)

                            Text(prompt)
                                .font(IrshadTheme.Typography.secondaryLabelDynamic)
                                .foregroundStyle(IrshadTheme.Colors.primaryText)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: IrshadTheme.Accessibility.minimumTapTarget)
                        .padding(.trailing, IrshadTheme.Layout.spacingComfortable)
                        .background {
                            RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                                .fill(IrshadTheme.Colors.surface.opacity(0.76))
                                .overlay {
                                    RoundedRectangle(cornerRadius: IrshadTheme.Layout.controlRadius, style: .continuous)
                                        .stroke(IrshadTheme.Colors.separator, lineWidth: 1)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("يملأ مربع النص بهذا المثال"))
                }
            }
        }
        .frame(maxWidth: 460)
    }
}

#Preview {
    WelcomeView(viewModel: AppEnvironment.live.makeJourneyViewModel())
}
