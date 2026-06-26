import SwiftUI

@main
struct IrshadApp: App {
    @State private var viewModel = AppEnvironment.live.makeJourneyViewModel()

    init() {
        FontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            JourneyView(viewModel: viewModel)
        }
    }
}
