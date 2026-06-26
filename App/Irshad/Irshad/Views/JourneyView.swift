import SwiftUI

struct JourneyView: View {
    var viewModel: JourneyViewModel

    var body: some View {
        WelcomeView(viewModel: viewModel)
    }
}

