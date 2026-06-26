import SwiftUI

@main
struct IrshadApp: App {
    @State private var viewModel = AppEnvironment.live.makeJourneyViewModel()

    var body: some Scene {
        WindowGroup {
            JourneyView(viewModel: viewModel)
        }
    }
}
