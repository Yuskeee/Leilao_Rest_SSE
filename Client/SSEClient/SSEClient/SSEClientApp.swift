//
//  SSEClientApp.swift
//  SSEClient
//
//  Created by Rodrigo Yamauchi on 21/10/25.
//

import SwiftUI
@main
struct SSEClientApp: App {
    @StateObject private var eventManager = EventManager()
    @State private var windows: [NSWindow] = [] // ✅ keep references
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(eventManager)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Window") {
                    DispatchQueue.main.async {
                        createNewWindow()
                    }
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
    
    @MainActor
    private func createNewWindow() {
        let eventManager = EventManager()
        let contentRect = NSRect(x: 100, y: 100, width: 1600, height: 900)
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.contentViewController = NSHostingController(
            rootView: RootView().environmentObject(eventManager)
        )
        window.makeKeyAndOrderFront(nil)
        
        windows.append(window) // ✅ hold a reference so it doesn’t deallocate
    }
}


struct RootView: View {
    var body: some View {
        ContentView()
    }
}
