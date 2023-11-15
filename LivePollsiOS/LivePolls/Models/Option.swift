//
//  Option.swift
//  LivePolls
//
//  Created by Juan Bazan Carrizo on 25/09/2023.
//

import Foundation

struct Option: Codable, Identifiable, Hashable {
    var id = UUID().uuidString
    let count: Int
    let name: String
}


extension String: Identifiable {
    public var id: Self { self }
}
