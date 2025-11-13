//
//  ContentView.swift
//  SSEClient
//
//  Created by Rodrigo Yamauchi on 21/10/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var eventManager = EventManager()
    
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    // --- Campos de Estado ---
    @State private var globalUserId = "user123" // ID do usuário "logado"
    
    // Estes campos agora são usados apenas para lances (bids)
    @State private var inputAuctionId = ""
    @State private var inputBidAmount = ""
    
    @State private var auctions: [Auction] = []
    
    @State private var showCreateAuction = false
    
    @State private var creationResult = ""

    // --- Formatadores de Data ---
    private var listDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    private var isoDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    // --- Variável Computada para Ordenação ---
    var sortedAuctions: [Auction] {
        auctions.sorted { (a1, a2) -> Bool in
            let a1IsActive = a1.status.lowercased() == "active"
            let a2IsActive = a2.status.lowercased() == "active"
            
            if a1IsActive && !a2IsActive { return true }
            if !a1IsActive && a2IsActive { return false }
            
            let date1 = listDateFormatter.date(from: a1.start_time) ?? Date.distantPast
            let date2 = listDateFormatter.date(from: a2.start_time) ?? Date.distantPast
            
            return date1 > date2
        }
    }

    var body: some View {
        NavigationView {
            ZStack{
                VStack(spacing: 15) {
                    
                    // --- Conexão ---
                    HStack {
                        TextField("Global User ID", text: $globalUserId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Connect") {
                            eventManager.connectSSE(userId: globalUserId)
                        }
                        Button("Disconnect") {
                            eventManager.disconnectSSE()
                        }
                    }
                    Text(eventManager.connectionStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // --- Lista de Leilões ---
                    Text("Auctions")
                        .font(.title2).bold()
                    
                    // --- MODIFICAÇÃO 1: Lista atualizada com botões ---
                    List(sortedAuctions, id: \.id) { auction in
                        HStack { // Container principal da linha
                            // Detalhes do Leilão
                            VStack(alignment: .leading) {
                                Text("Auction \(auction.id): \(auction.description)").bold()
                                Text("Start: \(auction.start_time)")
                                Text("End: \(auction.end_time)")
                                Text("Status: \(auction.status)")
                                    .foregroundColor(auction.status.lowercased() == "active" ? .green : .secondary)
                            }
                            
                            Spacer()
                            
                            HStack {
                                if eventManager.registeredAuctions.contains(auction.id) {
                                        Button("Cancel Registration") {
                                            Task {
                                                await eventManager.cancelInterest(
                                                    userId: globalUserId,
                                                    auctionId: String(auction.id)
                                                )
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.red)
                                    } else {
                                        Button("Register Interest") {
                                            Task {
                                                await eventManager.registerInterest(
                                                    userId: globalUserId,
                                                    auctionId: String(auction.id)
                                                )
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.blue)
                                    }
                            }
                        }
                        .padding(.vertical, 4) // Um pouco de preenchimento vertical
                    }
                    .frame(height: 250)
                    
                    Button("Update Auctions") {
                        Task {
                            self.auctions = await eventManager.fetchAuctions()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Divider()
                    
                    // --- Ações (Agora apenas Lances / Bidding) ---
                    VStack(spacing: 12) {
                        Text("Place Bid").bold()
                        TextField("Auction ID", text: $inputAuctionId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        // --- MODIFICAÇÃO 2: Botões de Interesse removidos daqui ---
                        // Aquele HStack com "Register Interest" e "Cancel Interest" foi removido.
                        
                        TextField("Bid Amount", text: $inputBidAmount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Place Bid") {
                            Task {
                                // A ação de "Place Bid" ainda usa os TextFields
                                await eventManager.placeBid(userId: globalUserId, auctionId: inputAuctionId, amount: inputBidAmount)
                            }
                        }
                    }
                    
                    Divider()
                    Spacer()
                    
                    // --- Feed de Eventos ---
                    Text("Event Feed:").font(.headline)
                    
                    Text(eventManager.apiMessage)
                        .font(.callout)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let bid = eventManager.lastBid {
                        Text("Last Bid: \(String(format: "%.2f", bid.amount)) by \(bid.user_id)")
                            .foregroundColor(.green)
                    } else if let error = eventManager.lastError {
                        Text("Bid Error: \(error.reason ?? "Invalid")")
                            .foregroundColor(.red)
                    } else if let payment = eventManager.paymentInfo {
                        Link("Go to Payment", destination: URL(string: payment.payment_link)!)
                            .buttonStyle(.borderedProminent)
                    }
                    
                    Spacer()
                    
                    // MARK: - Add Leilao
                    Button(action: {
                                    showCreateAuction = true
                                }) {
                                    
                                    Label("Adicionar Leilão", systemImage: "plus")
                                        .labelStyle(.iconOnly)
                                }
                                .sheet(isPresented: $showCreateAuction) {
                                    CreateAuctionView(showCreateAuction :$showCreateAuction)
                                }
                }
                .padding()
                .frame(minWidth: 400, minHeight: 600)
                .onAppear {
                    Task {
                        self.auctions = await eventManager.fetchAuctions()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
