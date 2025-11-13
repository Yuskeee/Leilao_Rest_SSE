//
//  CreateAuctionView.swift
//  SSEClient
//
//  Created by Akira Jensen on 12/11/25.
//

import SwiftUI

struct CreateAuctionView: View{
    
    @StateObject var eventManager = EventManager()
    
    @Binding var showCreateAuction: Bool
    @State private var auctionDesc = ""
    @State private var auctionStartDate = Date()
    @State private var auctionEndDate = Date().addingTimeInterval(3600)
    
    @State private var creationResult = ""
    
    private var isoDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    var body : some View {
        ZStack{
            VStack{
                HStack{
                    Spacer()
                    Button(action: {
                        showCreateAuction = false
                    }) {
                        
                        Label("Fechar", systemImage: "x.circle")
                            .labelStyle(.iconOnly)
                    }
                }
                Spacer()
            }
            VStack{
                Text("Create Auction").bold()
                TextField("Description", text: $auctionDesc)
                DatePicker("Start Time",
                           selection: $auctionStartDate,
                           in: Date()...,
                           displayedComponents: [.date, .hourAndMinute])
                DatePicker("End Time",
                           selection: $auctionEndDate,
                           in: auctionStartDate.addingTimeInterval(60)...,
                           displayedComponents: [.date, .hourAndMinute])
                
                Button("Create") {
                    Task {
                        let startString = isoDateFormatter.string(from: auctionStartDate)
                        let endString = isoDateFormatter.string(from: auctionEndDate)
                        
                        creationResult = await eventManager.createAuction(
                            description: auctionDesc,
                            startTime: startString,
                            endTime: endString
                        )
                        
                        showCreateAuction = false
                    }
                }
            }
            .padding(26)
        }
    }
}
