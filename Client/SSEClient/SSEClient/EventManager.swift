//
//  EventManager.swift
//  SSEClient
//
//  Created by Rodrigo Yamauchi on 21/10/25.
//

import Foundation
import EventSource
import Combine

class EventManager: ObservableObject {
    @Published var message: String = ""
    
    let urlRequest: URLRequest = URLRequest(url: URL(string: "http://localhost:5000/events")!)
    
    init () {
        Task {
            let eventSource = EventSource()
            let dataTask = eventSource.dataTask(for: urlRequest)
            
            for await event in dataTask.events() {
                switch event {
                case .open:
                    print("Connection was opened.")
                    DispatchQueue.main.async {
                        self.message = "Connection opened."
                    }
                case .error(let error):
                    print("Received an error:", error.localizedDescription)
                    DispatchQueue.main.async {
                        self.message = "Error: \(error.localizedDescription)"
                    }
                case .event(let event):
                    print("Received an event", event.data ?? "")
                    DispatchQueue.main.async {
                        self.message = event.data ?? ""
                    }
                case .closed:
                    print("Connection was closed.")
                    DispatchQueue.main.async {
                        self.message = "Connection closed."
                    }
                }
            }
        }
    }
}
