//
//  ContentView.swift
//  Irshad
//
//  Created by pac on 26/06/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = AppEnvironment.live.makeJourneyViewModel()

    var body: some View {
        JourneyView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}
