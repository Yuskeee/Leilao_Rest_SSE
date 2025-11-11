//
//  ContentView.swift
//  SSEClient
//
//  Created by Rodrigo Yamauchi on 21/10/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var eventManager = EventManager()
    @State private var inputAuctionId = ""
    @State private var inputUserId = ""
    @State private var inputBidAmount = ""
    @State private var auctions: [Auction] = []
    @State private var auctionDesc = ""
    @State private var auctionStart = ""
    @State private var auctionEnd = ""
    @State private var creationResult = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Auction Client")
                    .font(.title2).bold()

                List(auctions, id: \.id) { auction in
                    VStack(alignment: .leading) {
                        Text("Auction \(auction.id): \(auction.description)").bold()
                        Text("Start: \(auction.start_time)")
                        Text("End: \(auction.end_time)")
                        Text("Status: \(auction.status)")
                    }
                }
                .frame(height: 200)
                Button("Update Auctions") {
                    eventManager.fetchAuctions { newAuctions in
                        auctions = newAuctions
                    }
                }
                .buttonStyle(.borderedProminent)

                Divider()
                // Criar nova auction
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create Auction").bold()
                    TextField("Description", text: $auctionDesc)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Start Time (YYYY-MM-DDTHH:mm:ss)", text: $auctionStart)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("End Time (YYYY-MM-DDTHH:mm:ss)", text: $auctionEnd)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Create") {
                        eventManager.createAuction(description: auctionDesc, startTime: auctionStart, endTime: auctionEnd) { res in
                            creationResult = res
                        }
                    }
                    Text("Result: \(creationResult)").font(.caption)
                }

                Divider()
                VStack(spacing: 12) {
                    Text("Interest & Bidding").bold()
                    TextField("Auction ID", text: $inputAuctionId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("User ID", text: $inputUserId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    HStack {
                        Button("Register Interest") {
                            eventManager.registerInterest(userId: inputUserId, auctionId: inputAuctionId)
                        }
                        Button("Cancel Interest") {
                            eventManager.cancelInterest(userId: inputUserId, auctionId: inputAuctionId)
                        }
                    }
                    TextField("Bid Amount", text: $inputBidAmount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Place Bid") {
                        eventManager.placeBid(userId: inputUserId, auctionId: inputAuctionId, amount: inputBidAmount)
                    }
                }

                Divider()

                Text("Event feed:").foregroundColor(.secondary)
                Text(eventManager.message)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}
