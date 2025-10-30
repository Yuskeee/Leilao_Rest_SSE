//
//  ContentView.swift
//  SSEClient
//
//  Created by Rodrigo Yamauchi on 21/10/25.
//

import SwiftUI

import EventSource

struct ContentView: View {
    @ObservedObject var eventManager: EventManager
    
    init() {
        eventManager = EventManager()
    }
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(eventManager.message)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    ContentView()
}
