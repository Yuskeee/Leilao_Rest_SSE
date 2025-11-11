//
//  EventManager.swift
//  SSEClient
//
//  Created by Rodrigo Yamauchi on 21/10/25.
//

import Foundation
import EventSource
import Combine

struct Auction: Decodable {
    let id: Int
    let description: String
    let start_time: String
    let end_time: String
    let status: String
}


class EventManager: ObservableObject {
    @Published var message: String = ""
    let baseURL = "http://localhost:8000"
    let sseURL: URL = URL(string: "http://localhost:5000/events")!
    
    init () {
        // SSE Listener
        Task {
            let eventSource = EventSource()
            let dataTask = eventSource.dataTask(for: URLRequest(url: sseURL))
            for await event in dataTask.events() {
                switch event {
                case .open:
                    print("Connection was opened.")
                    Task { @MainActor in self.message = "Connection opened." }
                case .error(let error):
                    print("Received an error:", error.localizedDescription)
                    Task { @MainActor in self.message = "Error: \(error.localizedDescription)" }
                case .event(let event):
                    print("Received an event", event.data ?? "")
                    Task { @MainActor in self.message = event.data ?? "" }
                case .closed:
                    print("Connection was closed.")
                    Task { @MainActor in self.message = "Connection closed." }
                }
            }
        }
    }

    // REST API: Register Interest
    func registerInterest(userId: String, auctionId: String) {
        guard !userId.isEmpty, !auctionId.isEmpty else { return }
        guard let url = URL(string: "\(baseURL)/api/interest") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = ["user_id": userId, "auction_id": auctionId]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { return }
            if let result = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async { self.message = "Register: \(result)" }
            }
        }.resume()
    }

    // REST API: Cancel Interest
    func cancelInterest(userId: String, auctionId: String) {
        guard !userId.isEmpty, !auctionId.isEmpty else { return }
        guard let url = URL(string: "\(baseURL)/api/interest") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = ["user_id": userId, "auction_id": auctionId]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { return }
            if let result = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async { self.message = "Cancel: \(result)" }
            }
        }.resume()
    }
    
    // REST API: Place Bid
    func placeBid(userId: String, auctionId: String, amount: String) {
        guard !userId.isEmpty, !auctionId.isEmpty, !amount.isEmpty else { return }
        guard let url = URL(string: "\(baseURL)/api/bid") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = ["user_id": userId, "auction_id": auctionId, "amount": Double(amount) ?? 0.0]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { return }
            if let result = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async { self.message = "Bid: \(result)" }
            }
        }.resume()
    }
    
    // REST API: Create Auction
    func createAuction(description: String, startTime: String, endTime: String, completion: @escaping (String) -> Void) {
        guard !description.isEmpty, !startTime.isEmpty, !endTime.isEmpty else { return }
        guard let url = URL(string: "\(baseURL)/api/auction") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "description": description,
            "start_time": startTime,   // ISO
            "end_time": endTime        // ISO
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data else { return }
            if let result = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async { completion(result) }
            }
        }.resume()
    }
    
    // REST API: Fetch Auctions
    func fetchAuctions(completion: @escaping ([Auction]) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/auction") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            let auctions = (try? JSONDecoder().decode([Auction].self, from: data)) ?? []
            DispatchQueue.main.async {
                completion(auctions)
            }
        }.resume()
    }
}
