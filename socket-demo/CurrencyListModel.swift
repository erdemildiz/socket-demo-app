//
//  CurrencyListModel.swift
//  socket-demo
//
//  Created by Erdem ILDIZ on 23.12.2021.
//

import Foundation

// MARK: - CurrencyList
struct CurrencyList: Codable {
    let data: [CurrencyItem]
}

// MARK: - Datum
struct CurrencyItem: Codable {
    let id: Int
    let name, symbol, slug: String
    let lastUpdated: String
    let quote: Quote

    enum CodingKeys: String, CodingKey {
        case id, name, symbol, slug
        case lastUpdated = "last_updated"
        case quote
    }
}


// MARK: - Quote
struct Quote: Codable {
    let price: Price

    enum CodingKeys: String, CodingKey {
        case price = "USD"
    }
}

// MARK: - Usd
struct Price: Codable {
    let priceValue, volume24H : Double
    let lastUpdated: String

    enum CodingKeys: String, CodingKey {
        case priceValue = "price"
        case volume24H = "volume_24h"
        case lastUpdated = "last_updated"
    }
}
