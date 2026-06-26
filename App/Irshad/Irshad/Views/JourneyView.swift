import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Root of Irshad's continuous guided journey. Composes a full-screen
/// decorative background, the scrolling journey content, and the anchored input
/// overlay into one voice-first experience. Cross-screen presentation state
/// (saved plan, share sheet) is owned here; all behaviour is delegated to the
/// `JourneyViewModel`.
struct JourneyView: View {
    var viewModel: JourneyViewModel

    /// Empty and preparing reuse the self-contained welcome surface; every other
    /// status renders the composed journey experience.
    private var isWelcome: Bool {
        viewModel.journeyStatus == .empty || viewModel.journeyStatus == .preparing
    }

    private var isBackgroundActive: Bool {
        viewModel.voiceState == .listening
            || viewModel.voiceState == .processing
            || viewModel.isBackendBusy
    }

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        Group {
            if isWelcome {
                WelcomeView(viewModel: viewModel)
            } else {
                journeyExperience
            }
        }
        // Arabic-first: drive RTL from the resolved journey direction so the
        // whole screen (header, cards, dock) mirrors as one.
        .irshadLayoutDirection(viewModel.layoutDirection)
        // Keep the largest Dynamic Type sizes usable without clipping cards or
        // pushing primary actions off-screen.
        .irshadClampedDynamicType()
        // Mirror the system Reduce Motion setting into the ViewModel so every
        // child animation falls back to static emphasis together.
        .onAppear { viewModel.reduceMotionPreferred = systemReduceMotion }
        .onChange(of: systemReduceMotion) { _, newValue in
            viewModel.reduceMotionPreferred = newValue
        }
        .sheet(isPresented: savedPlanBinding) {
            SavedPlanView(viewModel: viewModel)
        }
        #if canImport(UIKit)
        .sheet(item: sharePayloadBinding) { payload in
            ShareSheetView(payload: payload)
        }
        #endif
    }

    private var journeyExperience: some View {
        ZStack(alignment: .bottom) {
            IrshadBackgroundView(isActive: isBackgroundActive)

            JourneyContentView(viewModel: viewModel)

            JourneyInputOverlayView(viewModel: viewModel)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var savedPlanBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showSavedPlan },
            set: { newValue in
                if !newValue {
                    viewModel.continueWithAssistant()
                }
            }
        )
    }

    private var sharePayloadBinding: Binding<SharePayload?> {
        Binding(
            get: { viewModel.sharePayload },
            set: { newValue in
                if newValue == nil {
                    viewModel.sharePayload = nil
                    viewModel.showShareSheet = false
                }
            }
        )
    }
}

#if canImport(UIKit)
/// System share sheet. `ShareService` only prepares the `SharePayload`; this view
/// performs the presentation.
private struct ShareSheetView: UIViewControllerRepresentable {
    let payload: SharePayload

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var items: [Any] = [payload.title, payload.body]
        items.append(contentsOf: payload.items)
        if let url = payload.url {
            items.append(url)
        }
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    JourneyView(viewModel: AppEnvironment.live.makeJourneyViewModel())
}
