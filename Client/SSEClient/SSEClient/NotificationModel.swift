//
//  NotificationModel.swift
//  SSEClient
//
//  Created by Rodrigo Yamauchi on 28/10/25.
//

import Foundation

struct NotificationModel: Codable {
    let notification_type: String
    let payload: String
}
